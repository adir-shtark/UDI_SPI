/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xil_printf.h"

/* 
 * יש לוודא ששמות ה-Base Addresses תואמים לשמות המוגדרים בקובץ xparameters.h שלך.
 * לרוב הם נגזרים משם ה-IP שנתת ב-Block Design.
 */
#define SPI_MASTER_BASEADDR XPAR_AXI_SPI_MASTER_0_BASEADDR
#define SPI_SLAVE_BASEADDR  XPAR_AXI_SPI_SLAVE_0_BASEADDR

/* 
 * מיפוי כתובות הרגיסטרים (Offsets) בדיוק כפי שהגדרנו במעטפת ה-AXI ב-Verilog:
 */
#define REG_START_OFFSET    0x00  // Write: Trigger transaction (Master only)
#define REG_BUSY_OFFSET     0x04  // Read:  Busy status (1 = Busy, 0 = Idle)
#define REG_DATAIN_OFFSET   0x08  // Write: Data to transmit
#define REG_DATAOUT_OFFSET  0x0C  // Read:  Data received
#define REG_CLKDIV_OFFSET   0x10  // Write: Clock divider (Master only)

int main() {
    u32 master_rx_data;
    u32 slave_rx_data;

    xil_printf("\r\n--- SPI Loopback Test Started ---\r\n");

    // 1. הכנת נתוני השידור של ה-Slave (הנתון שהוא "יענה" למאסטר)
    // נכתוב דפוס לסירוגין שקל לזהות: 101010... באוקסדצימלי AAAAAAAA
    Xil_Out32(SPI_SLAVE_BASEADDR + REG_DATAIN_OFFSET, 0xAAAAAAAA);

    // 2. הכנת נתוני השידור של ה-Master
    // נכתוב דפוס הפוך: 010101... באוקסדצימלי 55555555
    Xil_Out32(SPI_MASTER_BASEADDR + REG_DATAIN_OFFSET, 0x55555555);

    // 3. הגדרת מחלק השעון במאסטר
    // אם שעון המערכת הוא 100MHz, ערך של 10 יחלק אותו וייצר תדר SPI סביר לבדיקה
    Xil_Out32(SPI_MASTER_BASEADDR + REG_CLKDIV_OFFSET, 10);

    // 4. התחלת השידור (Trigger)
    xil_printf("Starting SPI transaction...\r\n");
    Xil_Out32(SPI_MASTER_BASEADDR + REG_START_OFFSET, 1);

    // 5. המתנה לסיום הפעולה (Polling על ביט ה-Busy של המאסטר)
    // אנו דוגמים את הכתובת בלולאה כל עוד הביט שווה ל-1
    while ((Xil_In32(SPI_MASTER_BASEADDR + REG_BUSY_OFFSET) & 0x01) == 1) {
        // ממתינים. בסביבה מבצעית אפשר להוסיף כאן Timeout כהגנה.
    }
    xil_printf("Transaction finished.\r\n");

    // 6. קריאת הנתונים שהתקבלו בשני הצדדים
    master_rx_data = Xil_In32(SPI_MASTER_BASEADDR + REG_DATAOUT_OFFSET);
    slave_rx_data  = Xil_In32(SPI_SLAVE_BASEADDR + REG_DATAOUT_OFFSET);

    // 7. הצגת התוצאות ובדיקת תקינות
    xil_printf("Master received: 0x%08X (Expected: 0xAAAAAAAA)\r\n", (unsigned int)master_rx_data);
    xil_printf("Slave received:  0x%08X (Expected: 0x55555555)\r\n", (unsigned int)slave_rx_data);

    if (master_rx_data == 0xAAAAAAAA && slave_rx_data == 0x55555555) {
        xil_printf("SUCCESS: SPI Loopback Test Passed!\r\n");
    } else {
        xil_printf("ERROR: Data mismatch.\r\n");
    }

    return 0;
}
