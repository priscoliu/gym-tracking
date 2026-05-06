SELECT 
        a.rs_dunsnumber AS DunsNumber,
		o.[originatingleadid] AS OriginatingLeadID,
        o.opportunityid AS GUID, 
        o.rs_opportunitynumber AS OpptyID, 
        o.[name] AS OpptySummary, 
        o.stepname AS 'Pipeline Phase',
        o.[description] AS Description, 
        o.rs_formname AS FormName, 
        o.[rs_productclassname] AS ProductClass, 
        o.[rs_productsubclassname] as ProductSubClass, 
        o.[rs_frequencyname] AS Frequency, 
        o.statuscodename AS OpptyStatus, 
        o.[statecodename] AS OpptyState, 
        o.[rs_opportunitytypename] AS OpptyType, 
        COALESCE(o.[rs_opportunitysubtypename], o.[rs_opportunitytypename]) AS OpptySubType,
        SUM(o.estimatedvalue) AS 'Est. Revenue (LCY)',
        SUM(o.[estimatedvalue_base]) AS 'Est. Revenue (USD)', 
        SUM(o.[rs_weightedincome]) AS 'Wt. Revenue (LCY)',
        SUM(o.[rs_weightedincome_base]) AS 'Wt. Revenue (USD)',
        t.isocurrencycode AS CCY, 
        o.rs_probabilityname AS 'Likelihood of Win', 
        o.[rs_premium_base] AS 'Premium (USD)',
        o.[rs_projectstartdate] AS 'Project Start Date', 
        o.[rs_latestmodifieddate] AS ModifiedOn, 
        o.[createdon] AS CreatedOn, 
        o.[actualclosedate] AS CloseDate, 
        COALESCE(o.[campaignidname], 'Not Informed') AS 'Source Campaign', 
        o.parentaccountidname AS Account, 
        a.[parentaccountidname] AS 'Parent Account',
        a.[rs_ultimateglobalparentname] AS 'Global Parent Account',
        a.accountnumber AS GCID, 
        a.rs_clientsegmentationname AS Tiers, 
        COALESCE(o.rs_regionname, s.territoryidname) AS 'Service Region', 
        COALESCE(o.rs_officename, s.rs_officename) AS 'Service Office', 
        COALESCE(office.rs_countryname, s.address1_country) AS 'Service Office Country', 
        COALESCE(o.[rs_incomeassignmentprofitcenter1name], s.[rs_profitcentername], o.[owneridname]) AS 'Profit Center',         
        o.[rs_incomeassignmentfinancelevel11name] AS 'Finance Level', 
        o.[owneridname] AS 'Opportunity Owner',
        s1.domainname AS 'Opportunity Owner UPN',
        o.[owneridname] AS 'Colleague Involved',  
        COALESCE(s.[rs_officename], o.rs_officename) AS 'Colleague Involved Office', 
        s.domainname AS 'Colleague Involved UPN',
		s.rs_profitcentername AS OwnerProfitCenter,
        MAX(tags.TagList) AS TagList,
        o.[rs_inceptiondate] AS 'First Income Date',
        a.[rs_industryname] AS 'Industry (Account Name) (Account)', 
        a.[rs_primarysiccodename] AS 'Primary SIC Code (Account Name)(Account)',
        a.rs_address1countryname AS 'Country (Account Name)(Account)',
        'Non Opportunity Service' AS 'Data Version'
    FROM 
        opportunity o 
        LEFT JOIN account a ON o.parentaccountid = a.accountid 
        LEFT JOIN systemuser s ON o.[ownerid] = s.[systemuserid]
        LEFT JOIN systemuser s1 ON o.[ownerid] = s1.[systemuserid]
        LEFT JOIN rs_office office ON office.[rs_officeid] = o.[rs_office] 
        LEFT JOIN transactioncurrency t ON o.transactioncurrencyid = t.[transactioncurrencyid]
        LEFT JOIN (
			SELECT 
				ot.opportunityid,
				STRING_AGG(tag.rs_name, ' / ') AS TagList
			FROM rs_rs_tagslist_opportunity ot
			LEFT JOIN rs_tagslist tag ON tag.rs_tagslistid = ot.rs_tagslistid
			GROUP BY ot.opportunityid
		) tags ON tags.opportunityid = o.opportunityid
    WHERE  
        o.statuscodename != 'Duplicate Entry' 
        AND (
            (
                o.rs_regionname IN ('Asia', 'Australasia', 'India', 'Vietnam', 'China', 'Australia', 'New Zealand')
                OR office.rs_subregionname IN ('Asia', 'Australasia', 'India', 'Vietnam', 'China', 'Australia', 'New Zealand')
                OR s.territoryidname IN ('Asia', 'Australasia', 'India', 'Vietnam', 'China', 'Australia', 'New Zealand')
            )
            OR s.domainname = 'christopher.au@willistowerswatson.com'
        )
        AND NOT EXISTS (
            SELECT 1
            FROM rs_opportunityservice os
            WHERE os.rs_opportunity = o.opportunityid AND os.statecode = 0
        )
		--AND o.rs_opportunitynumber = 1117533

    GROUP BY 
        o.[rs_premium_base], o.[originatingleadid],tags.TagList,
        a.rs_dunsnumber,
        s1.domainname,
        o.opportunityid,
        o.stepname,
        o.rs_opportunitynumber,
        o.[name],
        o.[description],
        o.rs_formname,
        o.[rs_productclassname],
        o.[rs_productsubclassname],
        o.[rs_frequencyname],
        o.statuscodename,
        o.[statecodename],
        o.[rs_opportunitytypename],
        o.[rs_opportunitysubtypename],
        t.isocurrencycode,
        o.rs_probabilityname,
        o.[rs_projectstartdate],
        o.[rs_latestmodifieddate],
        o.[createdon],
        o.[actualclosedate],
        o.[campaignidname],
        o.parentaccountidname,
        a.accountnumber,
        a.rs_clientsegmentationname,
        o.rs_regionname,
        o.rs_officename,
        office.rs_countryname,
        o.[rs_incomeassignmentprofitcenter1name],
        s.[rs_profitcentername],
        o.owneridname,
        s.territoryidname,
        s.address1_country,
        o.[rs_incomeassignmentfinancelevel11name],
        s.[rs_officename],
        s.[fullname],
        o.[rs_inceptiondate],
        a.[rs_industryname],
        a.[rs_primarysiccodename],
        a.rs_address1countryname,
        s.domainname,
        a.[parentaccountidname],
        s.rs_profitcentername,
        a.[rs_ultimateglobalparentname]