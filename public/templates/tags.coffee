h1 'Tags'
ul ->
	for tag in @tags
		li ->
			a href: "/tags/#{tag.name}", -> tag.name
			text " "
			small -> "(#{tag.count})"
