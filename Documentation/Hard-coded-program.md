# Hard coded program in a pseudo-code version

```
START:
    jump to DISPLAY_BIOS
    jump to TEST_PROGRAM

MAIN_LOOP:
    show current address on display
    wait until a button is pressed

    if button == LEFT:
        decrement low byte of address
    elif button == UP:
        decrement high byte
    elif button == RIGHT:
        increment low byte
    elif button == DOWN:
        increment high byte
    elif button == CENTER:
        record value
    else:
        continue waiting

    wait until button released
    go back to MAIN_LOOP
```