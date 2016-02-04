@HtmlImport("polymer_datepicker.html")
/// A simple date picker for dart and polymer
library polymer_datepicker;

import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';

import "package:web_components/web_components.dart";

import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import "dart:math" as math show min;

import "package:polymer_elements/paper_input.dart";
import "package:polymer_elements/iron_fit_behavior.dart";
import "package:polymer_elements/iron_overlay_behavior.dart";
import "package:polymer_elements/iron_resizable_behavior.dart";

class Day extends JsProxy  {

	static DateFormat fmt = new DateFormat("EEE");

	@reflectable DateTime date;

	@reflectable bool selected;

	@reflectable bool today;

	@reflectable bool other;

	@reflectable String weekDay;

	Day(DateTime d, int curMonth, DateTime selectedDate) : this.date = d
	{
		other = curMonth != date.month;
		selected = date.day == selectedDate?.day && date.year == selectedDate?.year && date.month == selectedDate?.month;
		DateTime now = new DateTime.now();
		today = date.month == now.month && date.year == now.year && date.day == now.day;
		weekDay = fmt.format(date);
	}
}

class Week extends JsProxy {
	@reflectable List<Day> days;

	Week(DateTime start, int curMonth, DateTime selectedDate) {
		days = new List.generate(7, (int i) => new Day(
			start.add(new Duration(days: i)), curMonth, selectedDate));
	}
}

@PolymerRegister("date-picker-overlay")
class DatePickerOverlay
	extends PolymerElement
	with IronFitBehavior, IronResizableBehavior, IronOverlayBehavior
{
	DatePicker _parent;

	Logger _logger = new Logger("polymer_datepicker_overlay");

	DateFormat dateFormatYear = new DateFormat("yyyy");
	DateFormat dateFormatMonth = new DateFormat("MMMM");
	DateFormat dateFormatMonthShort = new DateFormat("MMM");
	DateFormat dateFormatDayOfWeek = new DateFormat("EEEE");

	DatePickerOverlay.created() : super.created() {}

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

	@Property(observer: 'currentDateChanged')
	DateTime currentDate;

	@property
	List<Week> month;

	@property
	Week firstWeek;

	@property
	String monthDisplay;

	@property
	String monthShortDisplay;

	@property
	String yearDisplay;

	@property
	String yearSelectedDisplay;

	@property
	String dayDisplay;

	@property
	String dayOfWeekDisplay;

	@property
	List<String> monthList;

	@property
	List<int> yearList;

	@Property(observer: 'updateDate')
	int monthListSelected;

	@Property(observer: 'updateDate')
	int yearListSelected;

	@Property(notify: true, reflectToAttribute: true)
	bool quickChange;

	@property
	bool startWithSunday = false;


	void _updateMonth() {
		_logger.fine("Create month $currentDate");
		DateTime first = new DateTime.fromMillisecondsSinceEpoch(
			currentDate.millisecondsSinceEpoch);
		first = first.subtract(new Duration(days: first.day - 1));
		while (first.weekday != (startWithSunday ? DateTime.SUNDAY : DateTime.MONDAY)) {
			first = first.subtract(new Duration(days: 1));
		}
		set('month', new List.generate(6,
			(int w) => new Week(first.add(new Duration(days: 7 * w)),
			currentDate.month,
			_parent.selectedDate),
			growable: true
		));

		while(month.last.days[0].other) {
			removeItem('month', month.last);
		}
		set('firstWeek', month.first);
	}

	@reflectable
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
			set('currentDate', new DateTime(setYear, setMonth, currentDate.day));
	}

	@reflectable
	void currentDateChanged([_, __]) {
		set('monthDisplay', currentDate != null ? dateFormatMonth.format(currentDate) : "...");
		set('yearDisplay', currentDate != null ? dateFormatYear.format(currentDate) : "...");

		if (yearListSelected == null || (yearList.length > 0 && yearList[yearListSelected] != currentDate.year))
			set('yearListSelected', yearList.indexOf(currentDate.year));

		if (monthList != null && monthListSelected != currentDate.month - 1)
			set('monthListSelected', currentDate.month - 1);

		_updateMonth();
	}


	@reflectable
	void nextMonth([_, __]) {
		if (!(currentDate.month == 12 && currentDate.year + 1 > int.parse(_parent.maxYear))) {
			var cD = currentDate.subtract(new Duration(days: currentDate.day - 1));
			cD = cD.add(new Duration(days: 32));
			cD = cD.subtract(new Duration(days: cD.day - 1));
			set('currentDate', cD);
		}
	}

	@reflectable
	void prevMonth([_, __]) {
		if (!(currentDate.month == 1 && currentDate.year - 1 < int.parse(_parent.minYear))) {

			var cD = currentDate.subtract(new Duration(days: currentDate.day));
			cD = cD.subtract(new Duration(days: cD.day - 1));
			set('currentDate', cD);
		}
	}

	@reflectable
	void selDate(Event evt, var detail) {
		_parent.set('pickerOpen', false);

		DomRepeatModel mdl = new DomRepeatModel.fromEvent(convertToJs(evt));

		Day day = mdl["day"];
		_parent.set('selectedDate', day.date);

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
class DatePicker extends PolymerElement {

	DatePicker.created() : super.created() {
		_format = new DateFormat.yMd();

		if (!dateOnly)
			_format.add_Hm();

		if (selectedDate != null)
			set('textDate', _format.format(selectedDate));

	}

	@override
	void attached() {
		super.attached();
		_overlay = ($['pick'] as DatePickerOverlay).._parent = this;

		var tMonth = [];
		for (int x = 1; x < 13; x++)
			tMonth.add(_overlay.dateFormatMonth.format(new DateTime(0, x)));

		computeYears();
		_overlay
			..set('monthList', tMonth)
			..set('currentDate', new DateTime.now());

		_updateOverlayDate();
	}

	@override
	void detached() {
		super.detached();
		set('pickerOpen', false);
	}

	Logger _logger = new Logger("polymer_datepicker");
	DatePickerOverlay _overlay;
	DateFormat _format = new DateFormat.yMd();
	bool _comingFromTextChange = false;
	bool _clickedIn = false;
	PaperInput get _input => $['input'];

	@property
	bool pickerOpen = false;

	@Property(notify: true, reflectToAttribute: true)
	bool startWithSunday = false;

	/// A flag for field validation
	@Property(notify: true, reflectToAttribute: true, observer: 'updateRequired')
	bool required = false;

	/// A flag to enable / disable this field
	@Property(notify: true, reflectToAttribute: true)
	bool disabled = false;

	/// Label displayed in the field
	@Property(notify: true, reflectToAttribute: true)
	String label;

	@Property(notify: true, reflectToAttribute: true)
	bool quickChange = true;

	/// Current selected date, bindable r/w, notify.
	@Property(notify: true, reflectToAttribute: true, observer: 'selectedDateChanged')
	DateTime selectedDate;

	/// A flag to select only date without time info (default: false)
	@Property(notify: true, reflectToAttribute: true, observer: 'changeDateFormat')
	bool dateOnly = false;

	/// The date format (default: locale for `DateFormat.yMd`)
	@Property(notify: true, reflectToAttribute: true, observer: 'changeDateFormat')
	String dateFormat = new DateFormat.yMd().pattern;

	@Property(notify: true, reflectToAttribute: true, observer: 'computeYears')
	String minYear = "1960";

	@Property(notify: true, reflectToAttribute: true, observer: 'computeYears')
	String maxYear = "2020";

	/// Text version of the date bindable, r/w
	@Property(notify: true, reflectToAttribute: true, observer: 'textDateChanged')
	String textDate;

	@reflectable
	void updateRequired([_, __]) {
		_logger.fine("req date $required");
		($["input"] as PaperInput).validate();
	}

	@reflectable
	computeYears([_, __]) {
		if (_overlay != null) {
			var t = [],
				maxY = int.parse(maxYear),
				minY = int.parse(minYear);
			for (; maxY >= minY; maxY--)
				t.add(maxY);
			_overlay.set('yearList', t);
		}
	}

	@reflectable
	void changeDateFormat([_, __]) {
		_format = new DateFormat(dateFormat);
		if (!dateOnly) {
			_format.add_Hm();
		}
		if (selectedDate != null) {
			set('textDate', _format.format(selectedDate));
		}
	}

	@reflectable
	void selectedDateChanged([_,__]) {
		debounce("selected_date_changed",(){
			_logger.fine("Date changed : ${selectedDate}");

			_updateOverlayDate();

			String newText;
			if (selectedDate != null) {
				newText = _format.format(selectedDate);
			} else {
				newText = null;
			}

			if (newText == textDate || _comingFromTextChange) {
				_comingFromTextChange = false;
				return;
			}
			set('textDate', newText);
			_logger.fine("Selected Date is ${selectedDate}");
			fire("selectdate");
			fire("select-date-changed");
			updateStyles();
		});
	}

	@reflectable
	void textDateChanged([_,__]) {
		_logger.fine("Text changed : ${textDate}");
		try {
			DateTime newDate = _format.parse(textDate);
			if (newDate == selectedDate) {
				return;
			}
			_comingFromTextChange = true;
			set('selectedDate', newDate);

			if (pickerOpen) {
				_overlay.set('currentDate', selectedDate);
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
			_overlay.set('currentDate', selectedDate);
		}
		_overlay._updateMonth();
		set('pickerOpen', true);
	}

	@reflectable
	void cancelClose([_, __]) {
		_clickedIn = true;
	}

	//bool _refocus;
	@reflectable
	void inputLeft([_, __]) {

		if (_clickedIn) {
			if (!_input.focused ) {
				_input.focus();
				return;
			}
			_clickedIn = false;
			print("CLOSE CANCELLED");
			return;
		}
		print("CLOSING");
		set('pickerOpen', false);

		if (textDate == null || textDate.isEmpty) {
			set('selectedDate', null);
		}
		return;
	}

	@reflectable
	void doPos(Event e, var detail) {

		DatePickerOverlay ov = $['pick'] as DatePickerOverlay;
		// Ok : let's position the damn thing.
		Rectangle r = ov.parent.getBoundingClientRect();

		var left = r.left;
		var top = r.top;

		num h = window.innerHeight;

		num oh = _overlay.scrollHeight;

		top = math.min(h-oh,top);

		num w = window.innerWidth;
		num ow = _overlay.scrollWidth;

		left = math.min(w-ow,left);

		_overlay.style.position = "fixed";
		_overlay.style.left = "${left}px";
		_overlay.style.top = "${top}px";

	}

	@reflectable
	String computeInputClass(bool dateonly) => dateonly ? 'input_dateonly to-validate' : 'input_full to-validate';

	void _updateOverlayDate (){
		if (_overlay != null) {
			var n = selectedDate != null ? selectedDate : new DateTime.now();
			_overlay
				..set('dayOfWeekDisplay', _overlay.dateFormatDayOfWeek.format(n))
				..set('monthShortDisplay', _overlay.dateFormatMonthShort.format(n))
				..set('dayDisplay', "${n.day}")
				..set('yearSelectedDisplay', _overlay.dateFormatYear.format(n))
			;
		}
	}

	Stream<CustomEvent> get onSelectDate => _selectDateEvent.forTarget(this);
}

