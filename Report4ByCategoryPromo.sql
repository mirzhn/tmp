declare @analyzeDate date = '#analyzeDate'

;with rec as
	(
		select distinct g1_id as rootid, g1_name as rootname, g0_name as ProductType
		from 
		(SELECT p.Id,
				p.Name, 
				p.IsActive,
				g4.Id AS g4_id, 
				g4.Name AS g4_name, 
				g3.Id AS g3_id, 
				g3.Name AS g3_name, 
				g2.Id AS g2_id, 
				g2.Name AS g2_name, 
				g1.Id AS g1_id, 
				g1.Name AS g1_name, 
				g0.Id AS g0_id, 
                g0.Name AS g0_name
		FROM dbo.Products AS p INNER JOIN
             dbo.Groups AS g4 ON p.GroupId = g4.Id INNER JOIN
             dbo.Groups AS g3 ON g4.ParentId = g3.Id INNER JOIN
             dbo.Groups AS g2 ON g3.ParentId = g2.Id INNER JOIN
             dbo.Groups AS g1 ON g2.ParentId = g1.Id INNER JOIN
             dbo.Groups AS g0 ON g1.ParentId = g0.Id) t
		where IsActive = 1 --and g1_Id = 7
	),
	sq_sales as (
		select 
			ps.GroupId as rootid,
			sf.FormatGroup, 
			l.ShortName as ShopName,
			rg.Name as RegionName,
			city.Name as CityName,
			sum(case when ps.[Date] = @analyzeDate then ps.PromoQuantity end) as SalesDay,	
			sum(case when ps.[Date] = dateadd(day, -1, @analyzeDate) then ps.PromoQuantity end) as Sales1DayAgo,	
			sum(case when ps.[Date] = dateadd(day, -2, @analyzeDate) then ps.PromoQuantity end) as Sales2DayAgo,
			sum(case when ps.[Date] = dateadd(day, -3, @analyzeDate) then ps.PromoQuantity end) as Sales3DayAgo,
			sum(case when ps.[Date] = dateadd(day, -4, @analyzeDate) then ps.PromoQuantity end) as Sales4DayAgo,
			sum(case when ps.[Date] = dateadd(day, -5, @analyzeDate) then ps.PromoQuantity end) as Sales5DayAgo,
			sum(case when ps.[Date] = dateadd(day, -6, @analyzeDate) then ps.PromoQuantity end) as Sales6DayAgo,	
			coalesce(sum(case when ps.[Date] > dateadd(day, -7, @analyzeDate) and
						           ps.[Date] <= @analyzeDate then ps.PromoQuantity
					  else 0 end), 0) as SalesCategWeek,			
			coalesce(sum(case when ps.[Date] >= dateadd(day, -13, @analyzeDate) and
								   ps.[Date] < dateadd(day, -6, @analyzeDate) then ps.PromoQuantity
							  else 0 end), 0) as SalesCategWeekAgo,
			
			coalesce(sum(case when ps.[Date] > dateadd(day, -28, @analyzeDate) and
								   ps.[Date] <= @analyzeDate then ps.PromoQuantity
							  else 0 end), 0) as SalesCateg4Week,
			
			coalesce(sum(case when ps.[Date] >= dateadd(day, -55, @analyzeDate) and
								   ps.[Date] < dateadd(day, -27, @analyzeDate) then ps.PromoQuantity
							  else 0 end), 0) as SalesCateg4WeekAgo
		from LocationStateDayGroupSales ps
          join Locations l on l.Id = ps.LocationId
		  join StoreFormats sf on sf.Id = l.StoreFormatId
		  join Regions city on city.Id = l.RegionId
		  join Regions rg on rg.Id = city.ParentId
		where ps.[Date] > dateadd(day, -57, @analyzeDate) and
			  ps.[Date] <= @analyzeDate and
              l.IsActive = 1 and ps.GroupLevel = 1 
		group by ps.GroupId, sf.FormatGroup, l.ShortName, rg.Name, city.Name
	),
	sq_forecast as (
		select 
			sd.GroupId as rootid,
			sf.FormatGroup, 
			l.ShortName as ShopName,
			city.Name as CityName,
			rg.Name as RegionName,
			sum(case when sd.[Date] = @analyzeDate then sd.PromoQuantity end) as ForecastDay,	
			sum(case when sd.[Date] = dateadd(day, -1, @analyzeDate) then sd.PromoQuantity end) as Forecast1DayAgo,	
			sum(case when sd.[Date] = dateadd(day, -2, @analyzeDate) then sd.PromoQuantity end) as Forecast2DayAgo,
			sum(case when sd.[Date] = dateadd(day, -3, @analyzeDate) then sd.PromoQuantity end) as Forecast3DayAgo,
			sum(case when sd.[Date] = dateadd(day, -4, @analyzeDate) then sd.PromoQuantity end) as Forecast4DayAgo,
			sum(case when sd.[Date] = dateadd(day, -5, @analyzeDate) then sd.PromoQuantity end) as Forecast5DayAgo,
			sum(case when sd.[Date] = dateadd(day, -6, @analyzeDate) then sd.PromoQuantity end) as Forecast6DayAgo,
			coalesce(sum(case when sd.[Date] > dateadd(day, -7, @analyzeDate) and
						           sd.[Date] <= @analyzeDate then sd.PromoQuantity
					  else 0 end), 0) as ForecastCategWeek,
			
			coalesce(sum(case when sd.[Date] >= dateadd(day, -13, @analyzeDate) and
								   sd.[Date] < dateadd(day, -6, @analyzeDate) then sd.PromoQuantity
							  else 0 end), 0) as ForecastCategWeekAgo,
			
			coalesce(sum(case when sd.[Date] > dateadd(day, -28, @analyzeDate) and
								   sd.[Date] <= @analyzeDate then sd.PromoQuantity
							  else 0 end), 0) as ForecastCateg4Week,
			
			coalesce(sum(case when sd.[Date] >= dateadd(day, -55, @analyzeDate) and
								   sd.[Date] < dateadd(day, -27, @analyzeDate) then sd.PromoQuantity
							  else 0 end), 0) as ForecastCateg4WeekAgo
		from LostSalesDayGroups sd
          join Locations l on l.Id = sd.LocationId and sd.GroupLevel = 1
		  join StoreFormats sf on sf.Id = l.StoreFormatId
		  join Regions city on city.Id = l.RegionId
		  join Regions rg on rg.Id = city.ParentId
		where sd.[Date] > dateadd(day, -57, @analyzeDate) and
			  sd.[Date] <= @analyzeDate and
              l.IsActive = 1  
		group by sd.GroupId, sf.FormatGroup, l.ShortName, rg.Name, city.Name
	),
	sq1 as (
		select 
			coalesce(sd.rootid, ps.rootid) as rootid,
			coalesce(sd.FormatGroup, ps.FormatGroup) as StoreFormat,
			coalesce(sd.ShopName, ps.ShopName) as ShopName,
			coalesce(sd.RegionName, ps.RegionName) as RegionName,
			coalesce(sd.CityName, ps.CityName) as CityName,
			coalesce(ForecastDay, 0) as ForecastDay,
			coalesce(Forecast1DayAgo, 0) as Forecast1DayAgo,
			coalesce(Forecast2DayAgo, 0) as Forecast2DayAgo,
			coalesce(Forecast3DayAgo, 0) as Forecast3DayAgo,
			coalesce(Forecast4DayAgo, 0) as Forecast4DayAgo,
			coalesce(Forecast5DayAgo, 0) as Forecast5DayAgo,
			coalesce(Forecast6DayAgo, 0) as Forecast6DayAgo,
			coalesce(SalesDay, 0) as SalesDay,
			coalesce(Sales1DayAgo, 0) as Sales1DayAgo,
			coalesce(Sales2DayAgo, 0) as Sales2DayAgo,
			coalesce(Sales3DayAgo, 0) as Sales3DayAgo,
			coalesce(Sales4DayAgo, 0) as Sales4DayAgo,
			coalesce(Sales5DayAgo, 0) as Sales5DayAgo,
			coalesce(Sales6DayAgo, 0) as Sales6DayAgo,
			coalesce(ForecastCategWeek, 0) as ForecastCategWeek,
			coalesce(SalesCategWeek, 0) as SalesCategWeek,
			coalesce(ForecastCategWeekAgo, 0) as ForecastCategWeekAgo,
			coalesce(SalesCategWeekAgo, 0) as SalesCategWeekAgo,
			coalesce(ForecastCateg4Week, 0) as ForecastCateg4Week,
			coalesce(SalesCateg4Week, 0) as SalesCateg4Week,
			coalesce(ForecastCateg4WeekAgo, 0) as ForecastCateg4WeekAgo,
			coalesce(SalesCateg4WeekAgo, 0) as SalesCateg4WeekAgo 
		from sq_sales ps
		  left join sq_forecast sd  on ps.rootid = sd.rootid and
								   ps.FormatGroup = sd.FormatGroup and
								   ps.RegionName = sd.RegionName and
								   ps.ShopName = sd.ShopName and
								   ps.CityName = sd.CityName
	),

	sq2 as (
		select 
			r.rootid,
			r.rootname,
			r.ProductType,
			StoreFormat,
			ShopName,
			CityName,
			RegionName,
			ForecastDay,
			Forecast1DayAgo,
			Forecast2DayAgo,
			Forecast3DayAgo,
			Forecast4DayAgo,
			Forecast5DayAgo,
			Forecast6DayAgo,
			SalesDay,
			Sales1DayAgo,
			Sales2DayAgo,
			Sales3DayAgo,
			Sales4DayAgo,
			Sales5DayAgo,
			Sales6DayAgo,
			ForecastCategWeek,
			SalesCategWeek,
			ForecastCategWeekAgo,
			SalesCategWeekAgo,
			sum(ForecastCategWeek) over () as ForecastAllCategWeek,
			sum(SalesCategWeek) over () as SalesAllCategWeek,
			ForecastCateg4Week,
			SalesCateg4Week,
			ForecastCateg4WeekAgo,
			SalesCateg4WeekAgo,
			sum(ForecastCateg4Week) over () as ForecastAllCateg4Week,
			sum(SalesCateg4Week) over () as SalesAllCateg4Week
		from sq1
		  join rec r on sq1.rootid = r.rootid
		where sq1.rootid is not null
	),

	sq3 as (	
		
		select 
			2 as SortOrder,
			StoreFormat,
			'Все' as RegionName,
			'Все' as CityName,
			'Все' as ShopName,
			rootname as Categ_Name,
			sum(ForecastDay) as ForecastDay,
			sum(Forecast1DayAgo) as Forecast1DayAgo,
			sum(Forecast2DayAgo) as Forecast2DayAgo,
			sum(Forecast3DayAgo) as Forecast3DayAgo,
			sum(Forecast4DayAgo) as Forecast4DayAgo,
			sum(Forecast5DayAgo) as Forecast5DayAgo,
			sum(Forecast6DayAgo) as Forecast6DayAgo,
			sum(SalesDay) as SalesDay,
			sum(Sales1DayAgo) as Sales1DayAgo,
			sum(Sales2DayAgo) as Sales2DayAgo,
			sum(Sales3DayAgo) as Sales3DayAgo,
			sum(Sales4DayAgo) as Sales4DayAgo,
			sum(Sales5DayAgo) as Sales5DayAgo,
			sum(Sales6DayAgo) as Sales6DayAgo,
			sum(ForecastCategWeek) as ForecastCategWeek,
			sum(SalesCategWeek) as SalesCategWeek,
			sum(ForecastCategWeekAgo) as ForecastCategWeekAgo,
			sum(SalesCategWeekAgo) as SalesCategWeekAgo,
			max(ForecastAllCategWeek) as ForecastAllCategWeek,
			max(SalesAllCategWeek) as SalesAllCategWeek,
			sum(ForecastCateg4Week) as ForecastCateg4Week,
			sum(SalesCateg4Week) as SalesCateg4Week,
			sum(ForecastCateg4WeekAgo) as ForecastCateg4WeekAgo,
			sum(SalesCateg4WeekAgo) as SalesCateg4WeekAgo,
			max(ForecastAllCateg4Week) as ForecastAllCateg4Week,
			max(SalesAllCateg4Week) as SalesAllCateg4Week
		from sq2
		group by StoreFormat, rootname
		union 
		select 
			3 as SortOrder,
			StoreFormat,
			RegionName,
			'Все' as CityName,
			'Все' as ShopName,
			rootname as Categ_Name,			
			sum(ForecastDay) as ForecastDay,
			sum(Forecast1DayAgo) as Forecast1DayAgo,
			sum(Forecast2DayAgo) as Forecast2DayAgo,
			sum(Forecast3DayAgo) as Forecast3DayAgo,
			sum(Forecast4DayAgo) as Forecast4DayAgo,
			sum(Forecast5DayAgo) as Forecast5DayAgo,
			sum(Forecast6DayAgo) as Forecast6DayAgo,
			sum(SalesDay) as SalesDay,
			sum(Sales1DayAgo) as Sales1DayAgo,
			sum(Sales2DayAgo) as Sales2DayAgo,
			sum(Sales3DayAgo) as Sales3DayAgo,
			sum(Sales4DayAgo) as Sales4DayAgo,
			sum(Sales5DayAgo) as Sales5DayAgo,
			sum(Sales6DayAgo) as Sales6DayAgo,
			sum(ForecastCategWeek) as ForecastCategWeek,
			sum(SalesCategWeek) as SalesCategWeek,
			sum(ForecastCategWeekAgo) as ForecastCategWeekAgo,
			sum(SalesCategWeekAgo) as SalesCategWeekAgo,
			max(ForecastAllCategWeek) as ForecastAllCategWeek,
			max(SalesAllCategWeek) as SalesAllCategWeek,
			sum(ForecastCateg4Week) as ForecastCateg4Week,
			sum(SalesCateg4Week) as SalesCateg4Week,
			sum(ForecastCateg4WeekAgo) as ForecastCateg4WeekAgo,
			sum(SalesCateg4WeekAgo) as SalesCateg4WeekAgo,
			max(ForecastAllCateg4Week) as ForecastAllCateg4Week,
			max(SalesAllCateg4Week) as SalesAllCateg4Week
		from sq2
		group by StoreFormat, RegionName, rootname
		union 
		select 
			4 as SortOrder,
			StoreFormat,
			RegionName,
			CityName,
			'Все' as ShopName,
			rootname as Categ_Name,
			sum(ForecastDay) as ForecastDay,
			sum(Forecast1DayAgo) as Forecast1DayAgo,
			sum(Forecast2DayAgo) as Forecast2DayAgo,
			sum(Forecast3DayAgo) as Forecast3DayAgo,
			sum(Forecast4DayAgo) as Forecast4DayAgo,
			sum(Forecast5DayAgo) as Forecast5DayAgo,
			sum(Forecast6DayAgo) as Forecast6DayAgo,
			sum(SalesDay) as SalesDay,
			sum(Sales1DayAgo) as Sales1DayAgo,
			sum(Sales2DayAgo) as Sales2DayAgo,
			sum(Sales3DayAgo) as Sales3DayAgo,
			sum(Sales4DayAgo) as Sales4DayAgo,
			sum(Sales5DayAgo) as Sales5DayAgo,
			sum(Sales6DayAgo) as Sales6DayAgo,
			sum(ForecastCategWeek) as ForecastCategWeek,
			sum(SalesCategWeek) as SalesCategWeek,
			sum(ForecastCategWeekAgo) as ForecastCategWeekAgo,
			sum(SalesCategWeekAgo) as SalesCategWeekAgo,
			max(ForecastAllCategWeek) as ForecastAllCategWeek,
			max(SalesAllCategWeek) as SalesAllCategWeek,
			sum(ForecastCateg4Week) as ForecastCateg4Week,
			sum(SalesCateg4Week) as SalesCateg4Week,
			sum(ForecastCateg4WeekAgo) as ForecastCateg4WeekAgo,
			sum(SalesCateg4WeekAgo) as SalesCateg4WeekAgo,
			max(ForecastAllCateg4Week) as ForecastAllCateg4Week,
			max(SalesAllCateg4Week) as SalesAllCateg4Week
		from sq2
		group by StoreFormat, RegionName, CityName, rootname
		union 
		select 
			5 as SortOrder,
			StoreFormat,
			RegionName,
			CityName,
			ShopName,
			rootname as Categ_Name,
			sum(ForecastDay) as ForecastDay,
			sum(Forecast1DayAgo) as Forecast1DayAgo,
			sum(Forecast2DayAgo) as Forecast2DayAgo,
			sum(Forecast3DayAgo) as Forecast3DayAgo,
			sum(Forecast4DayAgo) as Forecast4DayAgo,
			sum(Forecast5DayAgo) as Forecast5DayAgo,
			sum(Forecast6DayAgo) as Forecast6DayAgo,
			sum(SalesDay) as SalesDay,
			sum(Sales1DayAgo) as Sales1DayAgo,
			sum(Sales2DayAgo) as Sales2DayAgo,
			sum(Sales3DayAgo) as Sales3DayAgo,
			sum(Sales4DayAgo) as Sales4DayAgo,
			sum(Sales5DayAgo) as Sales5DayAgo,
			sum(Sales6DayAgo) as Sales6DayAgo,
			sum(ForecastCategWeek) as ForecastCategWeek,
			sum(SalesCategWeek) as SalesCategWeek,
			sum(ForecastCategWeekAgo) as ForecastCategWeekAgo,
			sum(SalesCategWeekAgo) as SalesCategWeekAgo,
			max(ForecastAllCategWeek) as ForecastAllCategWeek,
			max(SalesAllCategWeek) as SalesAllCategWeek,
			sum(ForecastCateg4Week) as ForecastCateg4Week,
			sum(SalesCateg4Week) as SalesCateg4Week,
			sum(ForecastCateg4WeekAgo) as ForecastCateg4WeekAgo,
			sum(SalesCateg4WeekAgo) as SalesCateg4WeekAgo,
			max(ForecastAllCateg4Week) as ForecastAllCateg4Week,
			max(SalesAllCateg4Week) as SalesAllCateg4Week
		from sq2
		group by StoreFormat, RegionName, ShopName, CityName, rootname
	)
	, 
	sq_osa as (
		select 
		    SortOrder,
			StoreFormat,
			RegionName,
			CityName,
			ShopName,
			Categ_Name,
			case 
                when Sales6DayAgo = 0 and Forecast6DayAgo = 0 then 1 
                else (1 - Forecast6DayAgo/(Forecast6DayAgo + Sales6DayAgo))
            end as Osa6DayAgo,
			case 
                when Sales5DayAgo = 0 and Forecast5DayAgo = 0 then 1 
                else (1 - Forecast5DayAgo/(Forecast5DayAgo + Sales5DayAgo)) 
            end as Osa5DayAgo,
			case 
                when Sales4DayAgo = 0 and Forecast4DayAgo = 0 then 1 
                else (1 - Forecast4DayAgo/(Forecast4DayAgo + Sales4DayAgo))
            end as Osa4DayAgo,
			case 
                when Sales3DayAgo = 0 and Forecast3DayAgo = 0 then 1 
                else (1 - Forecast3DayAgo/(Forecast3DayAgo + Sales3DayAgo)) 
            end as Osa3DayAgo,
			case 
                when Sales2DayAgo = 0 and Forecast2DayAgo = 0 then 1 
                else (1 - Forecast2DayAgo/(Forecast2DayAgo + Sales2DayAgo)) 
            end as Osa2DayAgo,
			case 
                when Sales1DayAgo = 0 and Forecast1DayAgo = 0 then 1 
                else (1 - Forecast1DayAgo/(Forecast1DayAgo + Sales1DayAgo)) 
            end as Osa1DayAgo,
			case 
                when SalesDay = 0 and ForecastDay = 0 then 1 
                else (1 - ForecastDay/(ForecastDay + SalesDay)) 
            end as OsaDay,
			case 
                when SalesCategWeek = 0 and ForecastCategWeek = 0 then 1 
                else (1 - ForecastCategWeek/(ForecastCategWeek + SalesCategWeek)) 
            end as OsaCategWeek,
			case 
                when SalesCategWeekAgo = 0 and ForecastCategWeekAgo = 0 then 1 
                else (1 - ForecastCategWeekAgo/(ForecastCategWeekAgo + SalesCategWeekAgo)) 
            end as OsaCategWeekAgo,
			case 
                when SalesAllCategWeek = 0 and ForecastAllCategWeek = 0 then 1 
                else (1 - ForecastAllCategWeek/(ForecastAllCategWeek + SalesAllCategWeek)) 
            end as OsaAllCategWeek,
			case 
                when SalesCateg4Week = 0 and ForecastCateg4Week = 0 then 1 
                else (1 - ForecastCateg4Week/(ForecastCateg4Week + SalesCateg4Week)) 
            end as OsaCateg4Week,
			case 
                when SalesCateg4WeekAgo = 0 and ForecastCateg4WeekAgo = 0 then 1 
                else (1 - ForecastCateg4WeekAgo/(ForecastCateg4WeekAgo + SalesCateg4WeekAgo)) 
            end as OsaCateg4WeekAgo,
			case 
                when SalesAllCateg4Week = 0 and ForecastAllCateg4Week = 0 then 1 
                else (1 - ForecastAllCateg4Week/(ForecastAllCateg4Week + SalesAllCateg4Week)) 
            end as OsaAllCateg4Week
		from sq3
	)

	select
		StoreFormat,
		RegionName,
		CityName,
		ShopName,
		Categ_Name,
		Osa6DayAgo,
		Osa5DayAgo,
		Osa4DayAgo,
		Osa3DayAgo,
		Osa2DayAgo,
		Osa1DayAgo,
		OsaDay,
		OsaCategWeek,
		OsaCategWeek - OsaCategWeekAgo as OsaDiffWeek,
		OsaCategWeek - OsaAllCategWeek as OsaDiffAllCategWeek,
        '' as field1,
		OsaCateg4Week,
		OsaCateg4Week - OsaCateg4WeekAgo as OsaDiffWeek,
		OsaCateg4Week - OsaAllCateg4Week as OsaDiffAllCategWeek
	from sq_osa
	order by Categ_Name, SortOrder, RegionName, CityName