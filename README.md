#  A Simple date picker

# Usage

Just import in your component

    import "packages:polymer_datepicker/polymer_datepicker.dart"

and use in your html :

    <date-picker selectedDate="{{myDate}}" onlydate="true" label="Choose a date" on-selectdate="{{dateSelected}}"></date-picker>

``myDate`` should be an observable ``DateTime`` property. 


* fixed closing on blur bug
* Now using @HtmlImport
* Updated for latest polymer and paper things

