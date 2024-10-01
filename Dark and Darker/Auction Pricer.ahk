#SingleInstance force
#Requires AutoHotkey v2.0+
#include .\OCR.ahk ; https://github.com/Descolada/OCR
#include .\Helper.ahk

; https://github.com/MonzterDev/AHK-Game-Scripts





; Declare coordinate variables at the top
global x1 := 1344, y1 := 123, x2 := 1891, y2 := 1055

; Function to get coordinates
CaptureCoordinates() {
    ; Use global variables
    global x1, y1, x2, y2

    Tooltip("Move your mouse to the Top Left corner  of stash and click.")
    KeyWait("LButton", "D")
    MouseGetPos(&x1, &y1)
    Tooltip("Top Left corner set at: " x1 ", " y1)
    Sleep(1000)

    Tooltip("Move your mouse to the Top Right corner of stash and click.")
    KeyWait("LButton", "D")
    MouseGetPos(&x2, &y1)
    Tooltip("Top Right corner set at: " x2 ", " y1)
    Sleep(1000)

    Tooltip("Move your mouse to the Bottom Right corner of stash and click.")
    KeyWait("LButton", "D")
    MouseGetPos(&x2, &y2)
    Tooltip("Bottom Right corner set at: " x2 ", " y2)
    Sleep(1000)

    Tooltip("Move your mouse to the Bottom Left corner of stash and click.")
    KeyWait("LButton", "D")
    MouseGetPos(&x1, &y2)
    Tooltip("Bottom Left corner set at: " x1 ", " y2)
    Sleep(1000)    
    
    setTimer(RemoveTooltip, 3000)
    RemoveTooltip() {
        Tooltip("")  ; Clear the tooltip
    }
    
}

; Hotkey to set the coordinates
F9:: {
    coordinates := CaptureCoordinates()
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
    somethingElse := GetItemName(ocrResult)

    if (somethingElse[2] = "") {
        ToolTip("Item not found, try again.")
        SetTimer(RemoveTooltip, 3000)  ; Set timer for 3000 milliseconds (3 seconds)
        RemoveTooltip() {
        Tooltip("")  ; Clear the tooltip
            }
        return
    }

    enchantmentArr := GetItemEnchantments(ocrResult)

    MouseClick("Left", 850, 115, ,) ; View Market button
    Sleep(500)

    MouseClick("Left", 1785, 200, ,) ; Reset Filters button
    Sleep(400)


    MouseClick("Left", 150, 200, , ) ; Click item name selection
    Sleep(100)
    MouseClick("Left", 150, 250, , ) ; Click item name search box
    Sleep(200)
    Send(somethingElse[2]) ; Type item name
    Sleep(100)
    MouseClick("Left", 150, 250 + (somethingElse[1] * 27), , ) ; Click item name
    Sleep(100)

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
    superSet := ""
    returnArray := []
    returnArray.Push(0)
    returnArray.Push("")

    

    

    for i, item in ITEMS {
        if InStr(ocrResult, item) {
            itemName := item
            break
        }
    }

    for i, item in ITEMS{
        if InStr(item, itemName) {
            superSet .= item .= "|"
        }
    }
    sortedString := Sort(superSet, "D|")
    itemArray := StrSplit(sortedString,"|")

    ; Check for matches
    for i, BigItem in itemArray {
        if BigItem = itemName {
            returnArray[1] := i
            returnArray[2] := BigItem
            break
        }
    }
    Sleep(100)

    
    return returnArray
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

