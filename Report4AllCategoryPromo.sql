declare @analyzeDate date = '#analyzeDate'

;with
	params as (
		select
			@analyzeDate as repdate
	),
	rec as
	(
		select distinct g1_id as rootid, g1_name as rootname, g0_name as ProductType

		from (SELECT p.Id, 
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
        dbo.Groups AS g0 ON g1.ParentId = g0.Id
) as t
		where IsActive = 1 
	),
	sq_sales as (
		select 
			ps.GroupId as rootid,
			sum(case when ps.[Date] = pm.repdate then ps.PromoQuantity end) as SalesDay,	
			sum(case when ps.[Date] = dateadd(day, -1, pm.repdate) then ps.PromoQuantity end) as Sales1DayAgo,	
			sum(case when ps.[Date] = dateadd(day, -2, pm.repdate) then ps.PromoQuantity end) as Sales2DayAgo,
			sum(case when ps.[Date] = dateadd(day, -3, pm.repdate) then ps.PromoQuantity end) as Sales3DayAgo,
			sum(case when ps.[Date] = dateadd(day, -4, pm.repdate) then ps.PromoQuantity end) as Sales4DayAgo,
			sum(case when ps.[Date] = dateadd(day, -5, pm.repdate) then ps.PromoQuantity end) as Sales5DayAgo,
			sum(case when ps.[Date] = dateadd(day, -6, pm.repdate) then ps.PromoQuantity end) as Sales6DayAgo,	
			sum(case when ps.[Date] > dateadd(day, -7, pm.repdate) and
						  ps.[Date] <= pm.repdate then ps.PromoQuantity
					 else 0 end) as SalesCategWeek,			
			sum(case when ps.[Date] >= dateadd(day, -13, pm.repdate) and
						  ps.[Date] < dateadd(day, -6, pm.repdate) then ps.PromoQuantity
					 else 0 end) as SalesCategWeekAgo,
			
			sum(case when ps.[Date] > dateadd(day, -28, pm.repdate) and
						  ps.[Date] <= pm.repdate then ps.PromoQuantity
					 else 0 end) as SalesCateg4Week,
			
			sum(case when ps.[Date] >= dateadd(day, -55, pm.repdate) and
						  ps.[Date] < dateadd(day, -27, pm.repdate) then ps.PromoQuantity
					 else 0 end) as SalesCateg4WeekAgo
		from LocationStateDayGroupSales ps
          join Locations l on l.Id = ps.LocationId,
		  params pm
		where ps.[Date] > dateadd(day, -57, pm.repdate) and
			  ps.[Date] <= pm.repdate and
              l.IsActive = 1 and ps.GroupLevel = 1
		group by ps.GroupId
	)
	,
	sq_forecast as (
		select 
			sd.GroupId as rootid,
			sum(case when sd.[Date] = pm.repdate then sd.PromoQuantity end) as ForecastDay,	
			sum(case when sd.[Date] = dateadd(day, -1, pm.repdate) then sd.PromoQuantity end) as Forecast1DayAgo,	
			sum(case when sd.[Date] = dateadd(day, -2, pm.repdate) then sd.PromoQuantity end) as Forecast2DayAgo,
			sum(case when sd.[Date] = dateadd(day, -3, pm.repdate) then sd.PromoQuantity end) as Forecast3DayAgo,
			sum(case when sd.[Date] = dateadd(day, -4, pm.repdate) then sd.PromoQuantity end) as Forecast4DayAgo,
			sum(case when sd.[Date] = dateadd(day, -5, pm.repdate) then sd.PromoQuantity end) as Forecast5DayAgo,
			sum(case when sd.[Date] = dateadd(day, -6, pm.repdate) then sd.PromoQuantity end) as Forecast6DayAgo,	
			sum(case when sd.[Date] > dateadd(day, -7, pm.repdate) and
			              sd.[Date] <= pm.repdate then sd.PromoQuantity
				     else 0 end) as ForecastCategWeek,
			
			sum(case when sd.[Date] >= dateadd(day, -13, pm.repdate) and
			    		  sd.[Date] < dateadd(day, -6, pm.repdate) then sd.PromoQuantity
					 else 0 end) as ForecastCategWeekAgo,
			
			sum(case when sd.[Date] > dateadd(day, -28, pm.repdate) and
			  		      sd.[Date] <= pm.repdate then sd.PromoQuantity
					 else 0 end) as ForecastCateg4Week,
			
			sum(case when sd.[Date] >= dateadd(day, -55, pm.repdate) and
						  sd.[Date] < dateadd(day, -27, pm.repdate) then sd.PromoQuantity
					 else 0 end) as ForecastCateg4WeekAgo
		from LostSalesDayGroups sd
          join Locations l on l.Id = sd.LocationId and sd.GroupLevel = 1,
		  params pm
		where sd.[Date] > dateadd(day, -57, pm.repdate) and
			  sd.[Date] <= pm.repdate and
              l.IsActive = 1  
		group by sd.GroupId
	),
	sq1 as (
		select 
			coalesce(sd.rootid, ps.rootid) as rootid,
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
		from sq_forecast sd 
		  full join sq_sales ps on ps.rootid = sd.rootid,
		  params pm
	),

	sq2 as (
		select 
			r.rootid,
			r.rootname,
			r.ProductType,
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
	)
	,
	sq3 as (	
		select 
			case when GROUPING(ProductType) = 1 then -1 else 0 end as SortOrder,
			'Все' as StoreFormat,
			'Все' as RegionName,
			'Все' as CityName,
            'Все' as ShopName,
			case when GROUPING(ProductType) = 1 then 'Все' else ProductType end as Categ_Name,
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
		group by rollup(ProductType)
		union 
		select 
			1 as SortOrder,
			'Все' as StoreFormat,
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
		group by rootname
	), 
	sq_osa as (
		select 
		    SortOrder,
			StoreFormat,
			RegionName,
			CityName,
            ShopName,
			Categ_Name,
			case 
                when Sales6DayAgo = 0 and Forecast6DayAgo = 0 then -9999999.25
                else (1 - Forecast6DayAgo/(Forecast6DayAgo + Sales6DayAgo))
            end as Osa6DayAgo,
			case 
                when Sales5DayAgo = 0 and Forecast5DayAgo = 0 then -9999999.25
                else (1 - Forecast5DayAgo/(Forecast5DayAgo + Sales5DayAgo)) 
            end as Osa5DayAgo,
			case 
                when Sales4DayAgo = 0 and Forecast4DayAgo = 0 then -9999999.25
                else (1 - Forecast4DayAgo/(Forecast4DayAgo + Sales4DayAgo))
            end as Osa4DayAgo,
			case 
                when Sales3DayAgo = 0 and Forecast3DayAgo = 0 then -9999999.25 
                else (1 - Forecast3DayAgo/(Forecast3DayAgo + Sales3DayAgo)) 
            end as Osa3DayAgo,
			case 
                when Sales2DayAgo = 0 and Forecast2DayAgo = 0 then -9999999.25
                else (1 - Forecast2DayAgo/(Forecast2DayAgo + Sales2DayAgo)) 
            end as Osa2DayAgo,
			case 
                when Sales1DayAgo = 0 and Forecast1DayAgo = 0 then -9999999.25
                else (1 - Forecast1DayAgo/(Forecast1DayAgo + Sales1DayAgo)) 
            end as Osa1DayAgo,
			case 
                when SalesDay = 0 and ForecastDay = 0 then -9999999.25 
                else (1 - ForecastDay/(ForecastDay + SalesDay)) 
            end as OsaDay,
			case 
                when SalesCategWeek = 0 and ForecastCategWeek = 0 then -9999999.25
                else (1 - ForecastCategWeek/(ForecastCategWeek + SalesCategWeek)) 
            end as OsaCategWeek,
			case 
                when SalesCategWeekAgo = 0 and ForecastCategWeekAgo = 0 then -9999999.25
                else (1 - ForecastCategWeekAgo/(ForecastCategWeekAgo + SalesCategWeekAgo)) 
            end as OsaCategWeekAgo,
			case 
                when SalesAllCategWeek = 0 and ForecastAllCategWeek = 0 then -9999999.25
                else (1 - ForecastAllCategWeek/(ForecastAllCategWeek + SalesAllCategWeek)) 
            end as OsaAllCategWeek,
			case 
                when SalesCateg4Week = 0 and ForecastCateg4Week = 0 then -9999999.25
                else (1 - ForecastCateg4Week/(ForecastCateg4Week + SalesCateg4Week)) 
            end as OsaCateg4Week,
			case 
                when SalesCateg4WeekAgo = 0 and ForecastCateg4WeekAgo = 0 then -9999999.25
                else (1 - ForecastCateg4WeekAgo/(ForecastCateg4WeekAgo + SalesCateg4WeekAgo)) 
            end as OsaCateg4WeekAgo,
			case 
                when SalesAllCateg4Week = 0 and ForecastAllCateg4Week = 0 then -9999999.25 
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
		case when OsaCategWeek = -9999999.25 or OsaCategWeekAgo = -9999999.25 then -9999999.25 else OsaCategWeek - OsaCategWeekAgo end as OsaDiffWeek,
		case when OsaCategWeek = -9999999.25 then -9999999.25 else OsaCategWeek - OsaAllCategWeek end as OsaDiffAllCategWeek,
        '' as field1,
		OsaCateg4Week,
		case when OsaCateg4Week = -9999999.25 or OsaCateg4WeekAgo = -9999999.25 then -9999999.25 else OsaCateg4Week - OsaCateg4WeekAgo end as OsaDiffWeek,
		case when OsaCateg4Week = -9999999.25 then -9999999.25 else OsaCateg4Week - OsaAllCateg4Week end as OsaDiffAllCategWeek
	from sq_osa
	order by SortOrder, Categ_Name