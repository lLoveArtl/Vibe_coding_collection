import os
import re
import datetime
import asyncio
import websockets
from groq import Groq

# --- essential for AI working, you can find API in console.groq.com/keys ---
API_KEY = "your_API" 
SOURCE_FILE = "your txt file source for AI reading your timetable"

client = Groq(api_key=API_KEY)

# ==========================================
# memory reading logic
# ==========================================
def get_full_memory():
    if not os.path.exists(SOURCE_FILE): 
        return "Error: No data file directory."
    with open(SOURCE_FILE, "r", encoding="utf-8") as f: 
        return f.read()

# ==========================================
# proccessing WEBSOCKET & AI logic
# ==========================================
async def handle_gemini(websocket):
    print(f"🐾 One chat bot connect from: {websocket.remote_address}")
    try:
        async for message in websocket:
            # Catch signal from qml file
            if message.startswith("SEND_PROMPT"):
                prompt = message.split('\n', 1)[1]
                print(f"\n📩 Typing input: {prompt}")

                if not prompt.strip():
                    continue

                try:
                    mem = get_full_memory()
                    now = datetime.datetime.now()
                    
                    # --- Calculating days ---
                    code_ngay = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
                    target_code = code_ngay[now.weekday()]
                    target_str = f"hôm nay (Mã: {target_code})"
                    search_date = now.strftime("%d/%m/%y")

                    date_match = re.search(r'(\d{1,2})[/-](\d{1,2})', prompt)
                    if date_match:
                        try:
                            d, m = int(date_match.group(1)), int(date_match.group(2))
                            # 2026 year
                            check_date = datetime.date(2026, m, d)
                            target_code = code_ngay[check_date.weekday()]
                            target_str = f"ngày {d:02d}/{m:02d}/2026 (MÃ: {target_code})"
                            search_date = check_date.strftime("%d/%m/%y")
                        except: pass
                    elif "mai" in prompt.lower():
                        tomorrow = now + datetime.timedelta(days=1)
                        target_code = code_ngay[tomorrow.weekday()]
                        target_str = f"ngày mai (MÃ: {target_code})"
                        search_date = tomorrow.strftime("%d/%m/%y")

                    # --- call AI with response ---
                    response = client.chat.completions.create(
                        model="llama-3.3-70b-versatile",
                        messages=[
                            {
                                "role": "system", 
                                "content": (
                                    "Bạn là Trợ lý Mèo 🐾. Trả lời ngắn gọn, trực diện.\n"
                                    "LUẬT TÌM LỊCH BẮT BUỘC:\n"
                                    f"1. Ngày người dùng muốn tra cứu: '{search_date}' (Thuộc mã: {target_code}).\n"
                                    f"2. ĐIỀU KIỆN SỐNG CÒN: Bạn CHỈ được phép liệt kê môn học nếu chuỗi '{search_date}' xuất hiện CHÍNH XÁC trong mảng `Ngay_hoc` của môn đó.\n"
                                    "3. VÍ DỤ MINH HỌA CÁCH LỌC (Rất quan trọng):\n"
                                    f"   - Môn Điện tử số có Ngay_hoc: ['12/03/26', '09/04/26']. Vì không có '{search_date}' -> BẮT BUỘC BỎ QUA MÔN NÀY.\n"
                                    f"   - Môn Tiếng Trung có Ngay_hoc: ['23/04/26', '{search_date}']. Vì có '{search_date}' -> IN RA MÔN NÀY.\n"
                                    "4. Nếu sau khi lọc mà DgA hoặc A không còn môn nào, hãy mạnh dạn trả lời: 'Hôm nay DgA (hoặc A) không có lịch, được nghỉ meo~'.\n\n"
                                    "CƠ SỞ DỮ LIỆU CỦA BẠN:\n"
                                    f"{mem}"
                                )
                            },
                            {
                                "role": "user", 
                                "content": f"Câu hỏi ban đầu: '{prompt}'\n\nNhiệm vụ: Hãy rà soát thật kỹ các mảng `Ngay_hoc` trong CSDL để trả lời lịch ngày {search_date} của DgA và A."
                            }
                        ],
                        max_tokens=250,
                        temperature=0.0
                    )

                    ans = response.choices[0].message.content
                    print(f"✅ Python đã tính ra {target_code}. Mèo trả lời: {ans}")
                    
                    # send answer to qml file
                    await websocket.send(f"GEMINI_RESPONSE:{ans}")

                except Exception as e:
                    error_msg = f"Meo~ Lỗi gòi: {str(e)}"
                    print(error_msg)
                    await websocket.send(f"GEMINI_RESPONSE:{error_msg}")

    except websockets.exceptions.ConnectionClosed:
        print("🐾 Bé mèo đã ngắt kết nối tạm thời.")

async def main():
    # sever
    async with websockets.serve(handle_gemini, "localhost", 8080, reuse_address=True):
        print("🚀 CHÚ MÈO THẦN ĐỒNG ĐÃ SẴN SÀNG TẠI CỔNG 8080 (WEBSOCKET)!")
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())
    
    
