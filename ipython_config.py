c = get_config()
c.InteractiveShellApp.exec_lines = [
    'import runpy\n',
    '_ = runpy.run_path("/opt/scripts/seed.py", run_name="__main__")\n',
]
