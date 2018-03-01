function Get-DbaVoice {
	[CmdletBinding()]
	param (
		# We can't pass comma separated list of statuses either, so we either need to make multiple calls
		# or we need to only allow one category. This gets exponentially expensive when you combine it with
		# the Status parameter
		[ValidateSet('Bug', 'Documentation', 'Other', 'Setup and Deployment', 'Suggestions')]
		[string[]]$Category,

		# We need to use parameter sets here... Status and State should not be used together
		# See $statuses enum below for public vs closed statuses

		# We can't pass comma separated list of statuses either, so we either need to make multiple calls
		# or we need to only allow one status
		[ValidateSet('Under Review', 'Need Feedback', 'Unplanned', 'Planned', 'Started', 'Completed', 'Declined', 'Moved', 'Archived', 'Closed')]
		[string[]]$Status,

		[ValidateSet('Public', 'Closed')]
		[string]$State,

		[ValidateSet('Hot', 'Newest', 'Oldest', 'Votes')]
		[string]$Sort,

		[int]$Limit,

		[switch]$EnableException
	)

	begin {
		$categories = @{
			'Bug'                  = 325153
			'Documentation'        = 325156
			'Other'                = 325162
			'Setup and Deployment' = 325150
			'Suggestions'          = 325159
		}

		$statuses = @{
			'Under Review'  = 191761  # filter=public
			'Need Feedback' = 3535306 # filter=public
			'Unplanned'     = 3517354 # filter=public
			'Planned'       = 191762  # filter=public
			'Started'       = 191763  # filter=public

			'Completed'     = 191764  # filter=closed
			'Declined'      = 191765  # filter=closed
			'Moved'         = 3535297 # filter=closed
			'Archived'      = 3535300 # filter=closed
			'Closed'        = 3535303 # filter=closed
		}

		$baseUri = "https://feedback.azure.com/api/v1/forums/908035/suggestions.json?filter=$State"
	}

	process {

		$statusFilters = @()
		foreach ($statusParam in $Status) {
			$statusFilters += $statuses[$statusParam]
		}
		$statusString = $statusFilters -join ','

		$categoryFilters = @()
		foreach ($categoryParam in $Category) {
			$categoryFilters += $categories[$categoryParam]
		}
		$categoryString = $categoryFilters -join ','

		if (Test-Bound Limit) {
			$perPage = $Limit
		}
		else {
			$firstPageUri = $baseUri + "&per_page=1"
			if ($categoryString)   { $firstPageUri += "&category_id=$categoryString" }
			if ($statusString)     { $firstPageUri += "&status_id=$statusString" }
			if (Test-Bound Sort)   { $firstPageUri += "&sort=$Sort" }
			if (Test-Bound Filter) { $firstPageUri += "&filter=$Filter" }

			$firstPageContent = Invoke-WebRequest -Uri $firstPageUri
			$firstPage = ConvertFrom-Json $firstPageContent

			$perPage = $firstPage.response_data.total_records
		}
		Write-Message -Level Verbose -Message "Pulling back $perPage records"

		# get all of the content
		$allUri = $baseUri + "&per_page=$perPage"
		if ($categoryString)   { $allUri += "&category_id=$categoryString" }
		if ($statusString)     { $allUri += "&status_id=$statusString" }
		if (Test-Bound Sort)   { $allUri += "&sort=$Sort" }
		if (Test-Bound Filter) { $allUri += "&filter=$Filter" }

		$allUri = $baseUri + "&per_page=$perPage" + $statusUri + $categoryUri + $filterUri
		$allContent = Invoke-WebRequest -Uri $allUri -UseBasicParsing

		$json = ConvertFrom-Json $allContent.Content

		$json.suggestions | Select-Object -Property @(
			@{Name = 'ID'; Expression = { $_.id }},
			@{Name = 'ItemType'; Expression = { $_.category.name }},
			@{Name = 'Status'; Expression = { (Get-Culture).TextInfo.ToTitleCase($_.status.name) }},
			@{Name = 'Votes'; Expression = { $_.vote_count }},
			@{Name = 'Title'; Expression = { $_.title }},
			@{Name = 'Author'; Expression = { $_.creator.name }},
			@{Name = 'Link'; Expression = { $_.url }},
			@{Name = 'Created'; Expression = { [DateTime]$_.created_at }},
			@{Name = 'Closed'; Expression = { [DateTime]$_.closed_at }}
		) | Select-DefaultView -Property Link, Title, ID, Author, Created, Closed, Votes, ItemType, Status
	}
}