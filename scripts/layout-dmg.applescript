on run arguments
    set volumeName to item 1 of arguments

    tell application "Finder"
        tell disk volumeName
            open
            delay 1

            tell container window
                set current view to icon view
                delay 1
                set toolbar visible to false
                set statusbar visible to false
                set sidebar width to 0
                set bounds to {100, 100, 1000, 660}

            end tell

            set viewOptions to icon view options of container window
            tell viewOptions
                set icon size to 128
                set text size to 14
                set arrangement to not arranged
            end tell
            set background picture of viewOptions to file ".background:DMGBackground.png"

            set position of item "SpaceSwipeLab.app" to {225, 265}
            set position of item "Applications" to {675, 265}
            update without registering applications
            delay 2
            close
            open
            delay 2
        end tell
    end tell
end run
