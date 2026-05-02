import os
import re

replacements = {
    r"'Đã xảy ra lỗi không xác định.'": r"'An unknown error occurred.'",
    r"'Lỗi lấy sinh viên: ": r"'Error getting student: ",
    r"'Lỗi kết nối API'": r"'API connection error'",
    r"'Không có dữ liệu thành viên phù hợp.'": r"'No matching member data.'",
    r"'Danh sách Sinh Viên'": r"'Student List'",
    r"'Không tìm thấy lịch đăng ký với ID này.'": r"'Registration schedule with this ID not found.'",
    r'"Không tìm thấy lịch đăng ký với ID này."': r'"Registration schedule with this ID not found."',
    r"'Không có dữ liệu lịch đăng ký.'": r"'No registration schedule data.'",
    r'"Không có dữ liệu lịch đăng ký."': r'"No registration schedule data."',
    r"'Lịch Đăng Ký #'": r"'Registration Schedule #'",
    r"'Chưa xác định'": r"'Unknown'",
    r"'Đã đăng ký'": r"'Registered'",
    r"'Vui lòng nhập đủ các trường bắt buộc!'": r"'Please enter all required fields!'",
    r"'Tạo lịch đăng ký thành công!'": r"'Registration schedule created successfully!'",
    r"'Không thể tạo lịch.'": r"'Could not create schedule.'",
    r'"Không thể tạo lịch."': r'"Could not create schedule."',
    r"'Tạo lịch đăng ký mới'": r"'Create new registration schedule'",
    r"'Thêm vào nhóm'": r"'Add to team'",
    r"'Lớp hiện chưa có nhóm nào.'": r"'Class currently has no teams.'",
    r"'Thêm \$userName vào nhóm'": r"'Add \$userName to team'",
    r"'Chọn nhóm để thêm sinh viên này vào:'": r"'Select a team to add this student to:'",
    r"'Đã thêm sinh viên vào nhóm thành công!'": r"'Student successfully added to team!'",
    r"'Xác nhận thiết bị hợp lệ!'": r"'Valid equipment confirmed!'",
    r"'Mã thiết bị không hợp lệ'": r"'Invalid equipment code'",
    r"'Lỗi kết nối kiểm tra mã QR'": r"'QR code check connection error'",
    r"'Nhập hoặc quét mã thiết bị để xác nhận bộ dụng cụ cho buổi Lab.'": r"'Enter or scan equipment code to confirm kit for the Lab session.'",
    r"'Không có dữ liệu thiết bị cấp phát.'": r"'No issued equipment data.'",
    r"'Không tìm thấy thành viên!'": r"'Member not found!'",
    r"'Lỗi kết nối tra cứu API'": r"'API lookup connection error'",
    r"'Không có thông tin '": r"'No information '",
    r"'ID không hợp lệ'": r"'Invalid ID'",
    r"'Tìm theo Tên, Mã SV hoặc ID...'": r"'Search by Name, Student Code or ID...'",
    r"'Lỗi đăng nhập: ": r"'Login error: ",
    r"'Mã lỗi: ": r"'Error code: ",
    r"'Chi tiết: ": r"'Details: ",
    r"'Lỗi kết nối/API: ": r"'Connection/API error: ",
    r"'Tài khoản không tồn tại, vui lòng liên hệ admin cung cấp tài khoản'": r"'Account does not exist, please contact admin to provide an account'",
    r"'Đang đăng nhập...'": r"'Logging in...'",
    r"'Không thể tải thông tin. \(": r"'Failed to load info. ('",
    r"'Nhóm'": r"'Team'",
    r"'Lớp'": r"'Class'",
    r"'Giảng viên'": r"'Lecturer'",
    r"'Bảo vệ'": r"'Security'",
    r"'Trưởng bộ môn'": r"'Head of Department'",
    r"'Khác'": r"'Other'",
    r"'Mượn/Trả'": r"'Borrow/Return'",
    r"'Chờ duyệt'": r"'Pending'",
    r"'Lớp học'": r"'Class'",
    r"'Lịch biểu'": r"'Schedule'",
    r"'Quản lý'": r"'Management'",
    r"'Dữ liệu rỗng'": r"'Empty data'",
    r"'Không có dữ liệu'": r"'No data'",
    r"'Đóng'": r"'Close'",
    r"'Thiết bị'": r"'Equipment'",
    r"'Chi tiết'": r"'Details'",
    r"'Từ chối'": r"'Reject'",
    r"'Chấp nhận'": r"'Accept'",
    r"'Chưa có'": r"'None'",
    r"'Tất cả'": r"'All'",
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for pattern, repl in replacements.items():
        new_content = re.sub(pattern, repl, new_content)
        
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
