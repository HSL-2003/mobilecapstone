import os
import re

replacements = {
    r"'Thử lại'": r"'Retry'",
    r"'Điểm số - ": r"'Grade - ",
    r"'Trạng thái: ": r"'Status: ",
    r"'Thông báo'": r"'Notification'",
    r"'Chi tiết Lớp'": r"'Class Details'",
    r"'Danh sách Team'": r"'Team List'",
    r"'Đang sử dụng'": r"'In Use'",
    r"'Mượn: ": r"'Borrow: ",
    r"'Trả: ": r"'Return: ",
    r"'Phòng: ": r"'Room: ",
    r"'Check-in \(Bàn giao chìa khóa\)'": r"'Check-in (Key Handover)'",
    r"'Đang tải...'": r"'Loading...'",
    r"'Lịch Đăng Ký'": r"'Registration Schedule'",
    r"'Tìm theo ID...'": r"'Search by ID...'",
    r"'Quét mã thiết bị \(QR Check\)'": r"'Scan Equipment Code (QR Check)'",
    r"'Mã QR \(VD: OSC-01\)'": r"'QR Code (e.g., OSC-01)'",
    r"'Kiểm tra'": r"'Check'",
    r"'Danh sách Sinh Viên'": r"'Student List'",
    r"'Sĩ số: ": r"'Class Size: ",
    r"'Không tìm thấy'": r"'Not found'",
    r"'Vui lòng chọn'": r"'Please select'",
    r"'Thông tin'": r"'Information'",
    r"'Danh sách'": r"'List'",
    r"'Chưa có'": r"'None'",
    r"'Chi tiết'": r"'Details'",
    r"'Tên lớp'": r"'Class Name'",
    r"'Trang web'": r"'Website'",
    r"'Gửi'": r"'Submit'",
    r"'Tải lại'": r"'Reload'",
    r"'Nhập'": r"'Enter'",
    r"'Điểm số'": r"'Grade'",
    r"'Lớp'": r"'Class'",
    r"'Nhóm'": r"'Team'",
    r"'Sinh viên'": r"'Student'",
    r"'Giảng viên'": r"'Lecturer'",
    r"'Bảo vệ'": r"'Security'",
    r"'Đăng xuất'": r"'Logout'",
    r"'Xóa'": r"'Delete'",
    r"'Chỉnh sửa'": r"'Edit'",
    r"'Thêm'": r"'Add'",
    r"'Lưu'": r"'Save'",
    r"'Đồng ý'": r"'Agree'",
    r"'Từ chối'": r"'Reject'",
    r"'Chấp nhận'": r"'Accept'",
    r"'Xác nhận'": r"'Confirm'",
    r"'Thất bại'": r"'Failed'",
    r"'Đã hủy'": r"'Cancelled'",
    r"'Hoàn thành'": r"'Completed'",
    r"'Đang tiến hành'": r"'In Progress'",
    r"'Chờ xử lý'": r"'Pending'",
    r"'Bạn có chắc chắn muốn'": r"'Are you sure you want to'",
    r"'Vui lòng điền'": r"'Please fill in'",
    r"'Bắt buộc'": r"'Required'",
    r"'Không được để trống'": r"'Cannot be empty'",
    r"'Chọn ngày'": r"'Select Date'",
    r"'Chọn giờ'": r"'Select Time'",
    r"'Từ ngày'": r"'From Date'",
    r"'Đến ngày'": r"'To Date'",
    r"'Không có kết quả'": r"'No results'",
    r"'Đang kết nối'": r"'Connecting'",
    r"'Lỗi mạng'": r"'Network error'",
    r"'Không có mạng'": r"'No internet'",
    r"'Đã xảy ra lỗi'": r"'An error occurred'",
    r"'Trở về'": r"'Back'",
    r"'Tiếp tục'": r"'Next'",
    r"'Hoàn tất'": r"'Done'",
    r"'Cài đặt'": r"'Settings'",
    r"'Báo cáo'": r"'Report'",
    r"'Lịch sử'": r"'History'",
    r"'Thiết bị'": r"'Equipment'",
    r"'Phòng Lab'": r"'Lab Room'",
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
