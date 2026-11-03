@echo off
rem Roda os testes automaticos (sem janela): primeiro confere as salas
rem com o alcance real do pulo, depois o jogo.
set PYTHONIOENCODING=utf-8
python "%~dp0tools\validar_salas.py"
"%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64_console.exe" --headless --fixed-fps 60 --path "%~dp0" res://tests/run_tests.tscn
pause
