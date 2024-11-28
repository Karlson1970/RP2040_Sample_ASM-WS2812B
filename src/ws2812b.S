.section .data
seed: .word 0x12345678  // Начальное значение (seed)

.section .text
.global main

.equ IO_BANK0_BASE,         0x40014000  // Базовый адрес IO
.equ GPIO14_CTRL,           0x74        // Регистр настройки GPIO14
.equ GPIO16_CTRL,           0x84        // Регистр настройки GPIO16
.equ GPIO23_CTRL,           0xbc        // Регистр настройки GPIO23
.equ SIO_BASE,              0xd0000000  // Базовый адрес SIO
.equ GPIO_OUT_SET_REG,      0x14        // регистр установки GPIO
.equ GPIO_OUT_CLR_REG,      0x18        // регистр обнуления GPIO
.equ GPIO_OE_REG,           0x20        // регистр направления GPIO
.equ DELAY_NUM,             0x01000000  // Задержка перед отправкой нового цвета
.equ WS2812B_HIGH_TIME,     0x1e        // Время высокого уровня (0.8 мкс)
.equ WS2812B_LOW_TIME,      0x0e        // Время низкого уровня (0.4 мкс)
.equ WS2812B_RESET_TIME,    0xCE        // Время сброса (50 мкс)

main:
        // Инициализация GPIO14 GPIO16 GPIO23
    ldr r0, =IO_BANK0_BASE          // Базовый адрес
    mov r1, #5                      // Режим SIO
    ldr r2, =GPIO14_CTRL             
    str r1, [r0, r2]                // Включим режим SIO для GPIO14
    ldr r2, =GPIO16_CTRL             
    str r1, [r0, r2]                // Включим режим SIO для GPIO16
    ldr r2, =GPIO23_CTRL             
    str r1, [r0, r2]                // Включим режим SIO для GPIO23
 
    ldr r0, =SIO_BASE               // базовый адрес SIO
    mov r1, #0b10000001             // Создадим маску для двух портов 23 и 16 10000001 
    lsl r1, r1, #2                  // смещаем на два чтобы добавить порт 14 в маску
    add r1, r1, #1                  // добавляем 14 порт
    lsl r1, r1, #14                 // смещаем на 14 чтобы взведенные биты встали на свои места в маске   
    str r1, [r0, #GPIO_OE_REG]      // Настроим GPIO 14 16 23 как выход
                                    // биты 0-29 соответствуют портам GPIO0-29 установка каждого бита устанавливает соответствующий GPIO как выход    
        // Бесконечный цикл
loop1:
    bl random_number                // Получить псевдослучайное число 
    bl send_color                   // выводим цвет
    ldr r6, =DELAY_NUM
    bl delay                        // Задержка перед следующим выводом
    b loop1

// вход в функцию. В r0 - базовый адрес, в r1 - маска вывода в порты, r2 - цвет в формате GRB
send_color:
    push {r3, r6, lr}               // сохраняем регистры и точку входа в функцию в стек
    ldr r3, =0x800000               // будем бежать по данным 1 вправо 
next_bit:
    str r1, [r0, #GPIO_OUT_SET_REG] // Устанавливаем GPIO HIGH
    tst r2, r3                      // Проверяем текущий бит чему равен
    beq zero_bit
        // бит установлен
    mov r6, #WS2812B_HIGH_TIME      // Формируем 1 по протоколу ws2812b
    bl delay
    mov r6, #WS2812B_LOW_TIME
tst_next_bit:
    str r1, [r0, #GPIO_OUT_CLR_REG] // Устанавливаем GPIO LOW
    bl delay 
    lsr r3, r3, #1                  // Сдвигаемся на проверку следующего бита
    bne next_bit                    // Если пробежались по всем 24 битам то пропускаем, иначе уходим на новую проверку
    mov r6, #WS2812B_RESET_TIME     // Формируем сигнал сброс для отправки новых данных
    bl delay
    pop {r3, r6, pc}                // Востанавливаем значения из стека и Возврат из функции
zero_bit:
        // бит не установлен
    mov r6, #WS2812B_LOW_TIME       // Формируем 0 по протоколу ws2812b    
    bl delay
    mov r6, #WS2812B_HIGH_TIME  
    b tst_next_bit    

delay:
        // Простейшая задержка (не точно, для примера)
    sub r6, #1
    bne delay
    bx  lr

// Псевдослучайный генератор
// Выход: r2 - псевдослучайное 24-битное число
random_number:
    push {r1, r3, r4, r5, lr}
    ldr r1, =seed               // Загрузить адрес seed
    ldr r3, [r1]                // Загрузить текущее значение seed
    ldr r4, =#1664525           // A
    mul r3, r3, r4              // seed = A * seed
    ldr r5, =#1013904223        // C 
    add r3, r3, r5              // seed = seed + C
    str r3, [r1]                // Сохранить новое значение seed
    lsr r2, r3, #8              // Получить 24-битное число
    pop {r1, r3, r4, r5, pc}    // Возврат из функции