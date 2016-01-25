## 0.9.3

Big version leap caused by the recent `jefe-ization` of the project.
Fixed loop when selecting a date.

## 0.4.0+5

Added possibility to specify a `prefix` or a `suffix` inside the datepicker :
```
<polymer-datepicker><iron-icon icon="today" prefix></iron-icon></polymer-datepicker>
```

Fixed positioning when near window border.

## 0.4.0+4

Updated demo for latest autonotify, and other minor fixes.

## 0.4.0+3

Fixed bug occurring when compiling JS and minifying (never use single letter variables in `html` templates ...).
Fixed bug causing overlay to be closed when loosing focus with newer polymers.
Updated to user `autonotify_observe`.

## 0.4.0+2

Minor fixes and clean ups.

## 0.4.0+1

bugfixes

## 0.4.0

Various fixes and introducing material style (thanks to @barfittc ):
 - Added start with Sunday flag
 - deprecated dateonly (all lower), added dateOnly (camel cased) 
 - prevent the last week from being fully the next month.
 - added quick change flag

Updated deps on demo for `polymer-rc.10` upgrade
 
## 0.3.1+2

fixed an issue causing toubles when reopening the overlay.

## 0.3.1+1

minor fixes

## 0.3.1

polished `pubspec`, added `required` for validation

## 0.3.0+2

Added a small demo.
Upgraded to `polymer_elements` 1.0.0-rc.5

## 0.3.0+1

Updated readme.

## 0.3.0

Ported to `polymer` 1.0 (rc.9) with `polymer_autonotify`.
