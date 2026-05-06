SELECT 
        a.rs_dunsnumber AS DunsNumber,
		o.[originatingleadid] AS OriginatingLeadID,
        o.opportunityid AS GUID, 
        o.rs_opportunitynumber AS OpptyID, 
        os.rs_opportunityname AS OpptySummary, 
        o.stepname AS 'Pipeline Phase',
        o.[description] AS Description, 
        o.rs_formname AS FormName, 
        os.rs_lobname AS ProductClass, 
        os.rs_servicename AS ProductSubClass, 
        COALESCE(o.[rs_frequencyname], os.[rs_frequencyname]) AS Frequency, 
        o.statuscodename AS OpptyStatus, 
        o.[statecodename] AS OpptyState, 
        o.[rs_opportunitytypename] AS OpptyType, 
        COALESCE(o.[rs_opportunitysubtypename], o.[rs_opportunitytypename]) AS OpptySubType,
        COALESCE(SUM(ia.rs_share), SUM(os.rs_linevalue)) AS 'Est. Revenue (LCY)',
        COALESCE(SUM(ia.rs_share_base), SUM(os.rs_linevalue_base)) AS 'Est. Revenue (USD)',
		SUM(
		  CASE
			WHEN o.statecodename = 'WON'
			  THEN COALESCE(ia.rs_share, os.rs_linevalue, 0)
			ELSE COALESCE(ia.rs_share, os.rs_linevalue, 0)
				 * (CAST(REPLACE(o.rs_probabilityname, '%', '') AS FLOAT) / 100.0)
		  END
		) AS [Wt. Revenue (LCY)],

		SUM(
		  CASE
			WHEN o.statecodename = 'WON'
			  THEN COALESCE(ia.rs_share_base, os.rs_linevalue_base, 0)
			ELSE COALESCE(ia.rs_share_base, os.rs_linevalue_base, 0)
				 * (CAST(REPLACE(o.rs_probabilityname, '%', '') AS FLOAT) / 100.0)
		  END
		) AS [Wt. Revenue (USD)],

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
        COALESCE(office.[rs_subregionname], s.territoryidname) AS 'Service Region', 
        COALESCE(os.rs_officename, s.rs_officename) AS 'Service Office',
        COALESCE(office.rs_countryname, s.address1_country) AS 'Service Office Country', 
        COALESCE(IA.rs_profitcentername, s.rs_profitcentername, o.owneridname) AS 'Profit Center',
        COALESCE(pc.[rs_financelevel1name], office.rs_countryname, s.address1_country) AS 'Finance Level', 
        o.[owneridname] AS 'Opportunity Owner',
        s1.domainname AS 'Opportunity Owner UPN',
        COALESCE(IA.rs_colleaguename, s.[fullname], o.owneridname) AS 'Colleague Involved', 
        COALESCE(s.[rs_officename], os.rs_officename) AS 'Colleague Involved Office',
        s.domainname AS 'Colleague Involved UPN',
        s1.rs_profitcentername AS OwnerProfitCenter,
        MAX(tags.TagList) AS TagList,
        o.[rs_inceptiondate] AS 'First Income Date',
        a.[rs_industryname] AS 'Industry (Account Name) (Account)', 
        a.[rs_primarysiccodename] AS 'Primary SIC Code (Account Name)(Account)',
        a.rs_address1countryname AS 'Country (Account Name)(Account)',
        'Opportunity Service' AS 'Data Version'
    FROM 
        rs_opportunityservice os
        INNER JOIN opportunity o ON os.rs_opportunity = o.opportunityid 
        LEFT JOIN account a ON o.parentaccountid = a.accountid
        LEFT JOIN transactioncurrency t ON os.transactioncurrencyid = t.[transactioncurrencyid]
        LEFT JOIN rs_incomeassignment IA ON os.rs_opportunityserviceid = ia.rs_serviceline
        LEFT JOIN systemuser s ON IA.rs_colleague = s.[systemuserid]
        LEFT JOIN systemuser s1 ON o.[ownerid] = s1.[systemuserid]
        LEFT JOIN rs_profitcenter pc ON IA.[rs_profitcenter] = pc.[rs_profitcenterid]
        LEFT JOIN rs_office office ON office.[rs_officeid] = os.[rs_office]
		LEFT JOIN (
			SELECT
				ot.opportunityid,
				STRING_AGG(tag.rs_name, ' / ') AS TagList
				FROM rs_rs_tagslist_opportunity ot
				LEFT JOIN rs_tagslist tag ON tag.rs_tagslistid = ot.rs_tagslistid
				GROUP BY ot.opportunityid
		) tags ON tags.opportunityid = o.opportunityid
    WHERE  
        (
            (
                COALESCE(o.rs_regionname, office.rs_subregionname, s.territoryidname) IN ('Asia', 'Australasia', 'India', 'Vietnam', 'China', 'Australia', 'New Zealand')
                AND o.statuscodename != 'Duplicate Entry'
                AND os.statecode = 0 
                AND (IA.statecode = 0 OR IA.statecode IS NULL)
            )
            OR s1.domainname = 'christopher.au@willistowerswatson.com' 
            OR s.domainname = 'christopher.au@willistowerswatson.com'
        )
--and o.rs_opportunitynumber = 1298119
    GROUP BY
        o.[rs_premium_base], 		o.[originatingleadid],
        office.[rs_subregionname],
        a.rs_dunsnumber,
        os.[rs_frequencyname],
        s1.domainname,
        o.opportunityid, 
        o.stepname,
        os.[rs_opportunityserviceid],
        o.rs_opportunitynumber, 
        os.rs_opportunityname, 
        o.[description], 
        o.rs_formname, 
        os.rs_lobname, 
        os.rs_servicename, 
        o.[rs_frequencyname], 
        o.statuscodename, 
        o.[statecodename], 
        o.[rs_opportunitytypename], 
        o.[rs_opportunitysubtypename],
        os.[rs_linevalue], 
        os.[rs_linevalue_base], 
        o.rs_probabilityname, 
        t.isocurrencycode, 
        o.[rs_projectstartdate], 
        o.[rs_latestmodifieddate], 
        o.[createdon], 
        o.[actualclosedate], 
        o.[campaignidname], 
        o.parentaccountidname, 
        a.accountnumber, 
        a.rs_clientsegmentationname, 
        s.territoryidname,
        os.rs_officename, 
        office.rs_countryname, 
        ia.rs_profitcentername,
        s.rs_profitcentername, 
        o.owneridname,
        IA.rs_colleaguename,
        pc.[rs_financelevel1name],
        s.address1_country,
        s.[rs_officename], 
        s.[fullname], 
        o.[rs_inceptiondate], 
        a.[rs_industryname], 
        a.[rs_primarysiccodename], 
        a.rs_address1countryname,
        s.domainname,
        IA.rs_share,
        IA.rs_share_base,
        a.[parentaccountidname],
        s1.rs_profitcentername,
        a.[rs_ultimateglobalparentname]