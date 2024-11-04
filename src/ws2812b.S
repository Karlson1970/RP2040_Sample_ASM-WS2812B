.section .text
.global main

.equ IO_BANK0_BASE,         0x40014000  // Базовый адрес IO
.equ GPIO16_CTRL,           0x84        // Регистр настройки GPIO16 
.equ SIO_BASE,              0xd0000000  // Базовый адрес SIO
.equ GPIO_OUT_SET_REG,      0x14        // регистр установки GPIO
.equ GPIO_OUT_CLR_REG,      0x18        // регистр обнуления GPIO
.equ GPIO_OE_REG,           0x20        // регистр направления GPIO
.equ DELAY_NUM,             0x01800000  // Задержка перед отправкой нового цвета
.equ WS2812B_HIGH_TIME,     0x1e        // Время высокого уровня (0.8 мкс)
.equ WS2812B_LOW_TIME,      0x0e        // Время низкого уровня (0.4 мкс)
.equ WS2812B_RESET_TIME,    0xCE        // Время сброса (50 мкс)

main:
        // Инициализация GPIO16
    ldr r0, =IO_BANK0_BASE          // Базовый адрес
    mov r1, #5                      // Режим SIO
    ldr r2, =GPIO16_CTRL             
    str r1, [r0, r2]                // Включим режим SIO для GPIO16
 
    ldr r0, =SIO_BASE               // базовый адрес SIO
    mov r1, #1                      //  
    lsl r1, r1, #16                 // GPIO16   
    str r1, [r0, #GPIO_OE_REG]      // Настроим GPIO как выход
                                    // биты 0-29 соответствуют портам GPIO0-29 установка каждого бита устанавливает соответствующий GPIO как выход    
        // Бесконечный цикл
loop1:
   ldr r2, =0xff0000 // Зеленый цвет (GRB)
    bl send_color
    ldr r6, =DELAY_NUM
    bl delay
    ldr r2, =0x00ff00 // Красный цвет (GRB)
    bl send_color
    ldr r6, =DELAY_NUM
    bl delay
    ldr r2, =0x0000ff // Синий цвет (GRB)
    bl send_color
    ldr r6, =DELAY_NUM
    bl delay
    b loop1
  
send_color:
    mov r7, lr                      // сохраняем точку входа в функцию
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
    bx r7                           // Возврат из функции
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
