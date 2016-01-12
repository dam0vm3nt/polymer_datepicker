@HtmlImport("polymer_datepicker.html")
/// A simple date picker for dart and polymer
library polymer_datepicker;

import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';

import "package:web_components/web_components.dart";
import 'package:autonotify_observe/autonotify_observe.dart';

import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import "dart:js" as js;
import "dart:math" as math show min;

import "package:polymer_elements/paper_input.dart";
import "package:polymer_elements/paper_button.dart";
import "package:polymer_elements/paper_card.dart";
import "package:polymer_elements/paper_material.dart";
import "package:polymer_elements/paper_toggle_button.dart";
import "package:polymer_elements/paper_dropdown_menu.dart";
import "package:polymer_elements/paper_dialog.dart";

import "package:polymer_elements/iron_icon.dart";
import "package:polymer_elements/iron_fit_behavior.dart";
import "package:polymer_elements/iron_overlay_behavior.dart";
import "package:polymer_elements/iron_resizable_behavior.dart";
import "package:polymer_elements/iron_selector.dart";

import "package:polymer_elements/iron_icons.dart";

class Day extends Observable {

	static DateFormat fmt = new DateFormat("EEE");

	@observable DateTime date;

	@observable bool selected;

	@observable bool today;

	@observable bool other;

	@observable String weekDay;

	Day(DateTime d, int curMonth, DateTime selectedDate) : this.date = d
	{
		other = curMonth != date.month;
		selected = date.day == selectedDate?.day && date.year == selectedDate?.year && date.month == selectedDate?.month;
		DateTime now = new DateTime.now();
		today = date.month == now.month && date.year == now.year && date.day == now.day;
		weekDay = fmt.format(date);
	}
}

class Week extends Observable {
	@observable List<Day> days;

	Week(DateTime start, int curMonth, DateTime selectedDate) {
		days = new List.generate(7, (int i) => new Day(
			start.add(new Duration(days: i)), curMonth, selectedDate));
	}
}

@PolymerRegister("date-picker-overlay")
class DatePickerOverlay
	extends PolymerElement
	with IronFitBehavior, IronResizableBehavior, IronOverlayBehavior, Observable, AutonotifyBehavior
{
	DatePicker _parent;

	Logger _logger = new Logger("polymer_datepicker_overlay");

	DateFormat dateFormatYear = new DateFormat("yyyy");
	DateFormat dateFormatMonth = new DateFormat("MMMM");
	DateFormat dateFormatMonthShort = new DateFormat("MMM");
	DateFormat dateFormatDayOfWeek = new DateFormat("EEEE");

	DatePickerOverlay.created() : super.created() {}

	@reflectable
	showPickMonthYear ([_,__]) {
		pickerOpen = !pickerOpen;
	}


	@reflectable
	String computeDayClass(bool selected, bool today) {
		StringBuffer sb = new StringBuffer("dayCell");
		if (selected) {
			sb.write(" daySelected");
		}
		if (today && !selected) {
			sb.write(" dayToday");
		}
		else if (today && selected) {
			sb.write(" dayTodaySelected");
		}

		return sb.toString();
	}

	@reflectable
	String computeDay(Day day) => day.date.day.toString();

	@observable
	@property
	DateTime currentDate;

	@observable
	@property
	List<Week> month;

	@observable
	@property
	Week firstWeek;

	@observable
	@property
	String monthDisplay;

	@observable
	@property
	String monthShortDisplay;

	@observable
	@property
	String yearDisplay;

	@observable
	@property
	String yearSelectedDisplay;

	@observable
	@property
	String dayDisplay;

	@observable
	@property
	String dayOfWeekDisplay;

	@observable
	@property
	List<String> monthList;

	@observable
	@property
	List<int> yearList;

	@observable
	@property
	int monthListSelected;

	@observable
	@property
	int yearListSelected;

	@observable
	@property
	bool quickChange = false;

	@observable
	@property
	bool startWithSunday = false;

	@observable
	@property
	bool pickerOpen = false;


	void _updateMonth() {
		_logger.fine("Create month $currentDate");
		DateTime first = new DateTime.fromMillisecondsSinceEpoch(
			currentDate.millisecondsSinceEpoch);
		first = first.subtract(new Duration(days: first.day - 1));
		while (first.weekday != (startWithSunday ? DateTime.SUNDAY : DateTime.MONDAY)) {
			first = first.subtract(new Duration(days: 1));
		}
		month = new List.generate(6,
			(int w) => new Week(first.add(new Duration(days: 7 * w)),
			currentDate.month,
			_parent.selectedDate),
			growable: true
		);

		while(month.last.days[0].other) {
			month.removeLast();
		}
		firstWeek = month.first;
	}

	@reflectable
	@Observe("monthListSelected,yearListSelected")
	updateDate([_, __]) {

		if (null == _ || null == __)
			return;

		int _month = monthListSelected + 1,
			_year = yearList[yearListSelected],
			setMonth = currentDate.month,
			setYear = currentDate.year;

		if (_month != setMonth)
			setMonth = _month;
		if (_year != setYear)
			setYear = _year;

		if (currentDate.year != setYear || currentDate.month != setMonth)
			currentDate = new DateTime(setYear, setMonth, currentDate.day);
	}

	@reflectable
	@Observe("currentDate")
	void currentDateChanged([_, __]) {
		monthDisplay = currentDate != null ? dateFormatMonth.format(currentDate) : "...";
		yearDisplay = currentDate != null ? dateFormatYear.format(currentDate) : "...";

		if (yearListSelected == null || (yearList.length > 0 && yearList[yearListSelected] != currentDate.year))
			yearListSelected = yearList.indexOf(currentDate.year);

		if (monthListSelected != currentDate.month - 1)
			monthListSelected = currentDate.month - 1;

		_updateMonth();
	}


	@reflectable
	void nextMonth([_, __]) {
		if (!(currentDate.month == 12 &&
			currentDate.year + 1 > int.parse(_parent.maxYear))) {
			currentDate = currentDate.subtract(new Duration(days: currentDate.day - 1));
			currentDate = currentDate.add(new Duration(days: 32));
			currentDate = currentDate.subtract(new Duration(days: currentDate.day - 1));
		}
	}

	@reflectable
	void prevMonth([_, __]) {
		if (!(currentDate.month == 1 &&
			currentDate.year - 1 < int.parse(_parent.minYear))) {
			currentDate = currentDate.subtract(new Duration(days: currentDate.day));
			currentDate = currentDate.subtract(new Duration(days: currentDate.day - 1));
		}
	}

	@reflectable
	void selDate(Event evt, var detail) {
		_parent.pickerOpen = false;
		//fire("change");

		DomRepeatModel mdl = new DomRepeatModel.fromEvent(convertToJs(evt));

		Day day = mdl["day"];
		_parent.selectedDate = day.date;

	}

}

/**
 * A Polymer datepicker element.
 *
 * Use selectedDate to get and set date (use a date object for value).
 * date format is hard coded for now using the only reasonable format i.e. D/M/Y H:M.
 * beware to init locale data before using this comp
 *
 */
const EventStreamProvider<CustomEvent> _selectDateEvent = const EventStreamProvider<CustomEvent>('select-date-changed');

@PolymerRegister('date-picker')
/// Date picker component for dart and polymer
///
/// Fires `select-date-changed` when selected date changes.
///
/// Example:
///
///     <date-picker
///         select-date="{{myDateTimeField}}"
///         label="Select a date"
///         date-format="yyyy-MM-dd"
///         dateonly="true">
///     </date-picker>
///
class DatePicker extends PolymerElement with Observable, AutonotifyBehavior {

	@observable
	@property
	bool startWithSunday = false;

	DatePickerOverlay _overlay;
	/// A flag for field validation
	@observable
	@property
	bool required = false;

	/// A flag to enable / disable this field
	@observable
	@property
	bool disabled = false;

	/// Current selected date, bindable r/w, notify.
	@observable
	@Property(notify: true)
	DateTime selectedDate;

	/// Label displayed in the field
	@observable
	@property
	String label;

	/// A flag to select only date without time info (default: false)
	@observable
	@property
	bool dateOnly = false;

	@observable
	@property
	@deprecated
	bool dateonly = false;

	DateFormat format = new DateFormat.yMd();

	/// Text version of the date bindable, r/w
	@observable
	@property
	String textDate;

	@Observe("required")
	void updateRequired(_) {
		_logger.fine("req date $required");
		($["input"] as PaperInput).validate();
	}

	Logger _logger = new Logger("polymer_datepicker");

	/// The date format (default: locale for `DateFormat.yMd`)
	@observable
	@property
	String dateFormat = new DateFormat.yMd().pattern;

	@observable
	@Property(notify: true)
	bool quickChange = false;
	@observable
	@Property(notify: true)
	String minYear = "1960";
	@observable
	@Property(notify: true)
	String maxYear = "2020";

	@reflectable
	@Observe("minYear,maxYear")
	computeYears([_, __]) {
		if (_overlay != null) {
			var t = [],
				maxY = int.parse(maxYear),
				minY = int.parse(minYear);
			for (; maxY >= minY; maxY--)
				t.add(maxY);
			_overlay.yearList = t;
		}
	}

	DatePicker.created() : super.created() {
		format = new DateFormat.yMd();

		if (!dateOnly && !dateonly) {
			format.add_Hm();
		}
		if (selectedDate != null) {
			textDate = format.format(selectedDate);
		}
	}

	@Observe("dateOnly,dateonly,dateFormat")
	void changeDateFormat([_, __, ___]) {
		format = new DateFormat(dateFormat);
		if (!dateOnly && !dateonly) {
			format.add_Hm();
		}
		if (selectedDate != null) {
			textDate = format.format(selectedDate);
		}
	}

	@observable
	@property
	bool pickerOpen = false;

	@override
	void attached() {
		super.attached();
		_overlay = ($['pick'] as DatePickerOverlay)
			.._parent = this
			..currentDate = new DateTime.now();
		//..currentDateChanged();

		var tMonth = [];
		for (int x = 1; x < 13; x++)
			tMonth.add(_overlay.dateFormatMonth.format(new DateTime(0, x)));

		_overlay.monthList = tMonth;
		computeYears();

		_updateOverlayDate();
	}

	@reflectable
	void doPos(Event e, var detail) {

		DatePickerOverlay ov = $['pick'] as DatePickerOverlay;

		// Ok : let's position the damn thing.
		Rectangle r = ov.parent.getBoundingClientRect();
		var left = r.left;
		var top = r.top;

		num h = window.innerHeight;

		num oh = ov.scrollHeight;

		top = math.min(h-oh,top);

		num w = window.innerWidth;
		num ow = ov.scrollWidth;

		left = math.min(w-ow,left);

		ov.style.position = "fixed";
		ov.style.left = "${left}px";
		ov.style.top = "${top}px";

	}

	void _updateOverlayDate (){
		if (_overlay != null) {
			var n = selectedDate != null ? selectedDate : new DateTime.now();
			_overlay.dayOfWeekDisplay = _overlay.dateFormatDayOfWeek.format(n);
			_overlay.monthShortDisplay = _overlay.dateFormatMonthShort.format(n);
			_overlay.dayDisplay = "${n.day}";
			_overlay.yearSelectedDisplay = _overlay.dateFormatYear.format(n);
		}
	}

	@Observe("selectedDate")
	void selectedDateChanged([_]) {
		debounce("selected_date_changed",(){
			_logger.fine("Date changed : ${selectedDate}");

			_updateOverlayDate();

			String newText;
			if (selectedDate != null) {
				newText = format.format(selectedDate);
			} else {
				newText = null;
			}

			if (newText == textDate || _comingFromTextChange) {
				_comingFromTextChange = false;
				return;
			}
			textDate = newText;
			_logger.fine("Selected Date is ${selectedDate}");
			fire("selectdate");
			fire("select-date-changed");
			updateStyles();
		});
	}

	bool _comingFromTextChange = false;

	@Observe("textDate")
	void textDateChanged([_]) {
		_logger.fine("Text changed : ${textDate}");
		try {
			DateTime newDate = format.parse(textDate);
			if (newDate == selectedDate) {
				return;
			}
			_comingFromTextChange = true;
			selectedDate = newDate;

			if (pickerOpen) {
				_overlay.currentDate = selectedDate;
			}
		} catch (e) {
			_logger.fine("Invalid date :${textDate} : ${e}");
		}
		_logger.fine("Parsed date : ${selectedDate}");
		fire("selectdate");
		fire("select-date-changed");
	}

	@reflectable
	void showPicker([_, __]) {
		if (disabled) {
			return;
		}
		if (selectedDate != null) {
			_overlay.currentDate = selectedDate;
		}
		_overlay._updateMonth();
		pickerOpen = true;
	}

	bool _clickedIn = false;

	@reflectable
	void cancelClose([_, __]) {
		_clickedIn = true;
		_refocus = false;
	}

	bool _refocus;
	@reflectable
	void inputLeft([_, __]) {
		if (_clickedIn) {
			if (!_refocus) {
				$['input'].focus();
				_refocus=true;
				return;
			}
			_clickedIn = false;
			print("CLOSE CANCELLED");
			return;
		}
		print("CLOSING");
		pickerOpen = false;

		if (textDate == null || textDate.isEmpty) {
			selectedDate = null;
		}
		return;
	}

	@override
	void detached() {
		super.detached();
		pickerOpen = false;
	}

	@reflectable
	String computeInputClass(bool dateonly) =>
		dateonly ? 'input_dateonly to-validate' : 'input_full to-validate';


	Stream<CustomEvent> get onSelectDate => _selectDateEvent.forTarget(this);
}
