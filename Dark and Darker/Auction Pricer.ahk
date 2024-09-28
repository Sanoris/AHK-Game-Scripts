#SingleInstance force
#Requires AutoHotkey v2.0+
#include .\OCR.ahk ; https://github.com/Descolada/OCR
#include .\Helper.ahk
#include .\ScreenCapture.ahk 

; https://github.com/MonzterDev/AHK-Game-Scripts





; Declare coordinate variables at the top
global x1 := 0, y1 := 0, x2 := 0, y2 := 0

; Function to get coordinates
CaptureCoordinates() {
    ; Use global variables
    global x1, y1, x2, y2

    Tooltip("Move your mouse to the Top Left corner  of stash and click.")
    KeyWait("LButton", "D")
    MouseGetPos(&x1, &y1)
    Tooltip("Top Left corner set at: " x1 ", " y1)
    Sleep(2000)

    Tooltip("Move your mouse to the Top Right corner of stash and click.")
    KeyWait("LButton", "D")
    MouseGetPos(&x2, &y1)
    Tooltip("Top Right corner set at: " x2 ", " y1)
    Sleep(2000)

    Tooltip("Move your mouse to the Bottom Right corner of stash and click.")
    KeyWait("LButton", "D")
    MouseGetPos(&x2, &y2)
    Tooltip("Bottom Right corner set at: " x2 ", " y2)
    Sleep(2000)

    Tooltip("Move your mouse to the Bottom Left corner of stash and click.")
    KeyWait("LButton", "D")
    MouseGetPos(&x1, &y2)
    Tooltip("Bottom Left corner set at: " x1 ", " y2)
    Sleep(2000)
    
    return {x1: x1, y1: y1, x2: x2, y2: y2}
}

; Hotkey to set the coordinates
F9:: {
    coordinates := CaptureCoordinates()
    MsgBox("Coordinates for OCR.FromRect:`nX1: " coordinates.x1 "`nY1: " coordinates.y1 "`nX2: " coordinates.x2 "`nY2: " coordinates.y2)
}

; F3 hotkey for auction pricing logic
F3:: {
    ; Access global variables
    global x1, y1, x2, y2

    ; Check if the coordinates are valid
    if (x1 = 0 && y1 = 0 && x2 = 0 && y2 = 0) {
        MsgBox("Invalid coordinates. Please run the coordinate finder first.")
        return
    }

    ; Use the coordinates in OCR.FromRect
    ocrResult := OCR.FromRect(x1, y1, x2 - x1, y2 - y1, , scale := 1).Text

    rarity := GetItemRarity(ocrResult)
    itemName := GetItemName(ocrResult)

    if (itemName = "") {
        ToolTip("Item not found, try again.")
        return
    }

    enchantmentArr := GetItemEnchantments(ocrResult)

    MouseClick("Left", 850, 115, ,) ; View Market button
    Sleep(500)

    MouseClick("Left", 1785, 200, ,) ; Reset Filters button
    Sleep(400)

    MouseClick("Left", 400, 200, , ) ; Click rarity selection
    Sleep(100)
    if (rarity = "Uncommon") {
        MouseClick("Left", 400, 325, , ) ; Click rarity
    } else if (rarity = "Rare") {
        MouseClick("Left", 400, 350, , ) ; Click rarity
    } else if (rarity = "Epic") {
        MouseClick("Left", 400, 375, , ) ; Click rarity
    } else if (rarity = "Legend") {
        MouseClick("Left", 400, 400, , ) ; Click rarity
    } else if (rarity = "Unique") {
        MouseClick("Left", 400, 425, , ) ; Click rarity
    }
    Sleep(100)

    MouseClick("Left", 150, 200, , ) ; Click item name selection
    Sleep(100)
    MouseClick("Left", 150, 250, , ) ; Click item name search box
    Sleep(200)
    Send(itemName) ; Type item name
    Sleep(100)
    MouseClick("Left", 150, 275, , ) ; Click item name
    Sleep(100)
    MouseClick("Left", 1500, 200, , ) ; Click random attributes
    Sleep(100)

    for index, enchantmentL in enchantmentArr {
        MouseClick("Left", 1500, 250, , ) ; Click enchantment name search box
        Sleep(250)
        Send(enchantmentL) ; Type enchantment name
        Sleep(100)
        enchantmentPos := (index * 25) + (250)
        MouseClick("Left", 1500, enchantmentPos, , ) ; Click enchantment name
        Sleep(100)
    }

    Sleep(100)
    MouseClick("Left", 1800, 275, , ) ; Click search
}




GetItemRarity(ocrResult) {
    rarity := ""
    if InStr(ocrResult, "Uncommon") {
        rarity := "Uncommon"
    } else if InStr(ocrResult, "Rare") {
        rarity := "Rare"
    } else if InStr(ocrResult, "Epic") {
        rarity := "Epic"
    } else if InStr(ocrResult, "Legend") {
        rarity := "Legend"
    } else if InStr(ocrResult, "Unique") {
        rarity := "Unique"
    }

    return rarity
}

GetItemName(ocrResult) {
    itemName := ""
    ; TODO
    ; I tried using a while loop here because sometimes the OCR cannot detect the text.
    ; This didn't actually solve the issue. For now, just use hotkey again.
    while (itemName = "" && A_Index <= 3) {
        for i, item in ITEMS {
            if InStr(ocrResult, item) {
                itemName := item
                break
            }
        }

        if (itemName = "") {
            Sleep(100)
        }
    }

    return itemName
}

GetItemEnchantments(ocrResult) {
    ; Enchantments (Random Attributes) can be distinguished from the static attributes by the "+" sign and number on the left side of the enchantment name.
    ; For example, "+5 Magical Damage" is an enchantment, while "Magical Damage 5" is a static attribute.

    ; TODO
    ; This currently only finds the first enchantment. We need to find all enchantments.
    enchantmentsFound := []
    enchantment := ""

    for enchantmentI in ENCHANTMENTS {
        enchantmentRegex := "\+(\d+(?:\.\d+)?%?) " . enchantmentI
        if (matchPos := RegExMatch(ocrResult, enchantmentRegex, &matchObject)) {
            enchantmentValue := matchObject[1]
            enchantmentText := enchantmentValue . " " . enchantmentI
            enchantmentsFound.Push(enchantmentI)
        }
    }

    if (enchantmentsFound.Length > 0) {
        enchantmentsText := ""
        for index, enchantmentL in enchantmentsFound {
            enchantmentsText .= enchantmentL
            enchantment := enchantmentL
            if (index < enchantmentsFound.Length) {
                enchantmentsText .= ", "
            }
        }
        ;ToolTip(enchantmentsFound) ; Easy debug
        ;sleep(50000)
    }

    return enchantmentsFound
}
