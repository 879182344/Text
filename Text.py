import sys
import os
from PyQt5.QtWidgets import QApplication, QMainWindow, QTextEdit, QAction, QFileDialog, QMessageBox
from PyQt5.QtCore import QTimer

class Notepad(QMainWindow):
    def __init__(self):
        super().__init__()

        self.initUI()
        self.current_file = None
        self.autosave_interval = 60000  # 每分钟自动保存一次
        self.setup_autosave()

    def initUI(self):
        # 设置窗口标题
        self.setWindowTitle('text 记事本')
        # 设置窗口大小
        self.setGeometry(100, 100, 800, 600)

        # 创建文本编辑器
        self.text_edit = QTextEdit(self)
        self.setCentralWidget(self.text_edit)

        # 创建状态栏
        self.statusBar().showMessage('准备就绪')

        # 创建菜单栏
        menubar = self.menuBar()

        # 文件菜单
        file_menu = menubar.addMenu('文件')

        # 新建动作
        new_action = QAction('新建', self)
        new_action.setShortcut('Ctrl+N')
        new_action.setStatusTip('新建文件')
        new_action.triggered.connect(self.new_file)
        file_menu.addAction(new_action)

        # 打开动作
        open_action = QAction('打开', self)
        open_action.setShortcut('Ctrl+O')
        open_action.setStatusTip('打开文件')
        open_action.triggered.connect(self.open_file)
        file_menu.addAction(open_action)

        # 保存动作
        save_action = QAction('保存', self)
        save_action.setShortcut('Ctrl+S')
        save_action.setStatusTip('保存文件')
        save_action.triggered.connect(self.save_file)
        file_menu.addAction(save_action)

        # 退出动作
        exit_action = QAction('退出', self)
        exit_action.setShortcut('Ctrl+Q')
        exit_action.setStatusTip('退出应用')
        exit_action.triggered.connect(self.close)
        file_menu.addAction(exit_action)

    def setup_autosave(self):
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.autosave)
        self.timer.start(self.autosave_interval)

    def autosave(self):
        if self.text_edit.document().isModified():
            temp_file = self.get_temp_file_path()
            with open(temp_file, 'w', encoding='utf-8') as file:
                file.write(self.text_edit.toPlainText())
            self.statusBar().showMessage(f'自动保存到: {temp_file}')

    def get_temp_file_path(self):
        if self.current_file:
            return f"{self.current_file}.autosave"
        else:
            return "untitled.autosave"

    def new_file(self):
        self.text_edit.clear()
        self.current_file = None
        self.text_edit.document().setModified(False)
        self.statusBar().showMessage('新建文件')

    def open_file(self):
        options = QFileDialog.Options()
        file_name, _ = QFileDialog.getOpenFileName(self, "打开文件", "", "所有文件 (*);;文本文件 (*.txt)", options=options)
        if file_name:
            with open(file_name, 'r', encoding='utf-8') as file:
                self.text_edit.setText(file.read())
            self.current_file = file_name
            self.text_edit.document().setModified(False)
            self.statusBar().showMessage(f'打开文件: {file_name}')
            self.load_autosave(file_name)

    def load_autosave(self, file_name):
        temp_file = f"{file_name}.autosave"
        if os.path.exists(temp_file):
            with open(temp_file, 'r', encoding='utf-8') as file:
                content = file.read()
                if content != self.text_edit.toPlainText():
                    reply = QMessageBox.question(self, '自动保存恢复', '检测到自动保存的文件，是否恢复？',
                                                QMessageBox.Yes | QMessageBox.No, QMessageBox.No)
                    if reply == QMessageBox.Yes:
                        self.text_edit.setText(content)
                        self.text_edit.document().setModified(False)
                        self.statusBar().showMessage(f'恢复自动保存文件: {temp_file}')
                    os.remove(temp_file)  # 删除临时文件

    def save_file(self):
        if self.current_file is None:
            options = QFileDialog.Options()
            file_name, _ = QFileDialog.getSaveFileName(self, "保存文件", "", "所有文件 (*);;文本文件 (*.txt)", options=options)
            if file_name:
                self.current_file = file_name
        else:
            file_name = self.current_file

        if file_name:
            with open(file_name, 'w', encoding='utf-8') as file:
                file.write(self.text_edit.toPlainText())
            self.text_edit.document().setModified(False)
            self.statusBar().showMessage(f'保存文件: {file_name}')
            self.remove_autosave(file_name)

    def remove_autosave(self, file_name):
        temp_file = f"{file_name}.autosave"
        if os.path.exists(temp_file):
            os.remove(temp_file)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    notepad = Notepad()
    notepad.show()
    sys.exit(app.exec_())