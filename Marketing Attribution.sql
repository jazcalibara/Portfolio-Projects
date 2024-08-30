-- Opening dataset

		SELECT *
		FROM Attribution..[Lead Scoring]


-- Verifying that prospect_id is the primary key. Therefore there should be no duplicates.

		SELECT prospect_id
			, COUNT(*) AS id_count
		FROM Attribution..[Lead Scoring]
		GROUP BY prospect_id
		HAVING COUNT(*) > 1

		SELECT lead_number
			, COUNT(*) AS id_count
		FROM Attribution..[Lead Scoring]
		GROUP BY lead_number
		HAVING COUNT(*) > 1


-- There are several 'Select' which essentially means the same as NULL. To avoid confusion, the table needs to be updated where 'Select' becomes NULL.

		UPDATE Attribution..[Lead Scoring]
		SET how_did_you_hear_about_x_education = NULL
		WHERE how_did_you_hear_about_x_education = 'Select'

		UPDATE Attribution..[Lead Scoring]
		SET Specialization = NULL
		WHERE Specialization = 'Select'

		UPDATE Attribution..[Lead Scoring]
		SET Lead_Profile = NULL
		WHERE Lead_Profile = 'Select'

		UPDATE Attribution..[Lead Scoring]
		SET City = NULL
		WHERE City = 'Select'


-- Finding the count of lead sources

		SELECT DISTINCT lead_source
			, COUNT(*) as count
		FROM Attribution..[Lead Scoring]
		GROUP BY lead_source
		ORDER BY count DESC

-- We want to clean the dataset further as there are several records that aren't 'clean'
	-- Lead Source

		UPDATE Attribution..[Lead Scoring]
		SET Lead_Source = 'Paid Search' 
		WHERE Lead_Source = 'Google' 

		UPDATE Attribution..[Lead Scoring]
		SET Lead_Source = 'Paid Social' 
		WHERE Lead_Source = 'Facebook'

		UPDATE Attribution..[Lead Scoring]
		SET Lead_Source = 'Bing' 
		WHERE Lead_Source = 'bing'

		UPDATE Attribution..[Lead Scoring]
		SET Lead_Source = 'WeLearn' 
		WHERE Lead_Source = 'welearnblog_Home'

		UPDATE Attribution..[Lead Scoring]
		SET Lead_Source = 'Blog' 
		WHERE Lead_Source = 'blog'

		UPDATE Attribution..[Lead Scoring]
		SET Lead_Source = 'YouTube' 
		WHERE Lead_Source = 'youtubechannel'

		DELETE FROM Attribution..[Lead Scoring]
		WHERE Lead_Source = 'testone' -- Remove test lead source

	-- Convert to Boolean
		
		UPDATE Attribution..[Lead Scoring]
		SET Do_Not_Call = '0' 
		WHERE Do_Not_Call = 'No' 
	
		UPDATE Attribution..[Lead Scoring]
		SET Do_Not_Call = '1' 
		WHERE Do_Not_Call = 'Yes' 


-- Defining implicit (lead_source) versus explicit lead sources vs offline marketing
	-- Implicit lead source refers to inferred information through collection
	-- Explicit lead source refers to user-defined information


		SELECT [Lead_Source] AS implicit_lead_source
			, COUNT(*) AS count
		FROM Attribution..[Lead Scoring]
		GROUP BY [Lead_Source]
		ORDER BY count DESC;
		
		SELECT [How_did_you_hear_about_X_Education] AS explicit_lead_source
			, COUNT(*) AS count
		FROM Attribution..[Lead Scoring]
		GROUP BY [How_did_you_hear_about_X_Education]
		ORDER BY count DESC;


-- What is the conversion rate per implicit lead source?

		WITH conversion_percentage
		AS
			(
			SELECT lead_source
				, COUNT(CASE WHEN converted = '1' THEN 1 END) AS conversions	
				, COUNT(*) AS count
			FROM Attribution..[Lead Scoring]
			GROUP BY lead_source
			)
		SELECT *
			, (100.0 * conversions/count) AS conversion_rate
		FROM conversion_percentage
		ORDER BY conversions DESC


-- How many leads opted-in to receive comms (courses / supply chain / DM content) per implicit lead source?

		SELECT lead_source
			, COUNT(CASE WHEN [Receive_More_Updates_About_Our_Courses] = 'Yes' THEN 1 END) AS comms_opt_in_courses
			, COUNT(CASE WHEN [Update_me_on_Supply_Chain_Content] = 'Yes' THEN 1 END) AS comms_opt_in_supply_chain
			, COUNT(CASE WHEN [Get_updates_on_DM_Content] = 'Yes' THEN 1 END) AS comms_opt_in_dm_content
		FROM Attribution..[Lead Scoring]
		GROUP BY lead_source
		ORDER BY lead_source
	
-- What is the distribution of lead_quality among leads?

		SELECT lead_quality
			, COUNT(*) AS count
		FROM Attribution..[Lead Scoring]
		GROUP BY lead_quality
		ORDER BY lead_quality 

-- What is the most effective implicit lead source? / What implicit lead source brings the best lead quality?

		SELECT lead_source
			, lead_quality
			, COUNT(*) AS count
		FROM Attribution..[Lead Scoring]
		WHERE lead_quality = 'High in Relevance'
		GROUP BY lead_source, lead_quality
		ORDER BY count DESC
	
-- How many converted per implicit lead source per city?

		SELECT city
			, COUNT(*) AS count
		FROM Attribution..[Lead Scoring]
		GROUP BY city
		ORDER BY city ASC

-- What specializations are most interested in our product?
		
		SELECT [Specialization]
			, COUNT(*) AS count
		FROM Attribution..[Lead Scoring]
		GROUP BY [Specialization]
		ORDER BY count DESC 


-- How many received a free copy or promo and converted?

		SELECT COUNT(*)
		FROM Attribution..[Lead Scoring]		
		WHERE [A_free_copy_of_Mastering_The_Interview] = '1'

-- Did receiving a free copy help to convert leads?

		SELECT lead_quality
			, COUNT(*) AS count
		FROM Attribution..[Lead Scoring]		
		WHERE [A_free_copy_of_Mastering_The_Interview] = '1'
		GROUP BY lead_quality
		ORDER BY count DESC
