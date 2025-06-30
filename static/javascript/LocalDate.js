import element from 'https://cdn.jsdelivr.net/gh/darkwiiplayer/js@3724b3e/element.js'

element(class LocalDate extends HTMLTimeElement {
	static is = 'time'
	static attributes = { datetime: { get: date => new Date(date) } }

	constructor() {
		super()
	}

	datetimeChanged() {
		this.innerText = this.datetime.toDateString()
	}
})
