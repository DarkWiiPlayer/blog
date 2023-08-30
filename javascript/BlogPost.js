import element from 'https://cdn.jsdelivr.net/gh/darkwiiplayer/js@3724b3e/element.js'

element(class BlogPost extends HTMLElement {
	connectedCallback() {
		this.filter()
	}

	get tags() {
		return new Set(Array.from(this.querySelectorAll("post-tag")).map(e => e.innerText))
	}

	filter() {
		const search = new URL(document.location).searchParams
		if (search.has("tag")) {
			this.hidden = !this.tags.has(search.get("tag"))
		}
	}
})
