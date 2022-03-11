file print
set disassembly-flavor intel
# дизассемблировать блоки кода
disas _start
disas fin
b start
run
# цикл пока счетчик команд меньше
# адреса метки fin
while $pc<fin
# показать текущую инструкцию
x/i $pc
# выполнить инструкцию
ni
# показать регистры
i r
end
c
quit
