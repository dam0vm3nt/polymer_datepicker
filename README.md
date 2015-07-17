#  A Simple date picker

## Usage

Just import in your component

    import "package:polymer_datepicker/polymer_datepicker.dart"

and use in your html :

```HTML
<date-picker selectedDate="{{myDate}}" onlydate="true" label="Choose a date" on-selectdate="{{dateSelected}}"></date-picker>
```

``myDate`` should be an observable ``DateTime`` property. 

This component uses ``intl`` package for week days and month names therefore locale should be properly initialized before using it (see ``intl`` library for more info).


## Changes

* fixed closing on blur bug
* Now using @HtmlImport
* Updated for latest polymer and paper things

