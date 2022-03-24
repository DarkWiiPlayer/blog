import element from 'https://cdn.jsdelivr.net/gh/darkwiiplayer/js@3724b3e/element.js'
import {html, empty} from 'https://cdn.jsdelivr.net/gh/darkwiiplayer/js@cdaeac1/skooma.js'

export default element(class BlogPost extends HTMLElement {
	static attributes = { name: true }
	constructor() {
		super()
		this.post = posts.find(post => post.head.slug == this.name)
	}
	async nameChanged() {
		this.replace(
			html.a({href: `/blog${this.post.head.uri}`}, html.h2(this.post.head.title)),
			this.post.head.description ? html.p(this.post.head.description) : undefined,
			html.p(html.time$localDate({datetime: this.post.head.date, class: ["timestamp"]}))
		)
	}
})
