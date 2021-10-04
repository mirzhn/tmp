declare @analyzeDate date = '#analyzeDate'

;with
	params as (
		select
			@analyzeDate as repdate
	),
	sq_forecast as (
		select 
			ls.*

		from LostSalesDayGroups ls
          join Locations l on l.Id = ls.LocationId and ls.GroupLevel = 1,
		  params pm
		Where ls.Date > dateadd(day, -56, pm.repdate) and
		      ls.Date <= pm.repdate and
              l.IsActive = 1

	),
	sq_sales as (
		select 
			ls.*

		from LocationStateDayGroupSales ls
          join Locations l on l.Id = ls.LocationId and ls.GroupLevel = 1,
		  params pm
		Where ls.Date > dateadd(day, -56, pm.repdate) and
		      ls.Date <= pm.repdate and
              l.IsActive = 1
	),
	sq1 as (
		select 
			sf.Name as StoreFormatName,
			sf.[FormatGroup] as StoreFormat,
			coalesce(sf.LFL, ' ') as LFL,
			r.Name as RegionName,
			city.Name as CityName,
			l.ShortName as ShopName,
			smt.Name as ManagementTypeName,
			(select coalesce(sum(Quantity), 0) from sq_forecast where LocationId = l.Id and [Date] = pm.repdate) as ForecastDay,
			(select coalesce(sum(Quantity), 0) from sq_forecast where LocationId = l.Id and [Date] = dateadd(day, -1, pm.repdate)) as Forecast1DayAgo,
			(select coalesce(sum(Quantity), 0) from sq_forecast where LocationId = l.Id and [Date] = dateadd(day, -2, pm.repdate)) as Forecast2DayAgo,
			(select coalesce(sum(Quantity), 0) from sq_forecast where LocationId = l.Id and [Date] = dateadd(day, -3, pm.repdate)) as Forecast3DayAgo,
			(select coalesce(sum(Quantity), 0) from sq_forecast where LocationId = l.Id and [Date] = dateadd(day, -4, pm.repdate)) as Forecast4DayAgo,
			(select coalesce(sum(Quantity), 0) from sq_forecast where LocationId = l.Id and [Date] = dateadd(day, -5, pm.repdate)) as Forecast5DayAgo,
			(select coalesce(sum(Quantity), 0) from sq_forecast where LocationId = l.Id and [Date] = dateadd(day, -6, pm.repdate)) as Forecast6DayAgo,
			(select coalesce(sum(Quantity), 0) from sq_sales where LocationId = l.Id and [Date] = pm.repdate) as SalesDay,
			(select coalesce(sum(Quantity), 0) from sq_sales where LocationId = l.Id and [Date] = dateadd(day, -1, pm.repdate)) as Sales1DayAgo,
			(select coalesce(sum(Quantity), 0) from sq_sales where LocationId = l.Id and [Date] = dateadd(day, -2, pm.repdate)) as Sales2DayAgo,
			(select coalesce(sum(Quantity), 0) from sq_sales where LocationId = l.Id and [Date] = dateadd(day, -3, pm.repdate)) as Sales3DayAgo,
			(select coalesce(sum(Quantity), 0) from sq_sales where LocationId = l.Id and [Date] = dateadd(day, -4, pm.repdate)) as Sales4DayAgo,
			(select coalesce(sum(Quantity), 0) from sq_sales where LocationId = l.Id and [Date] = dateadd(day, -5, pm.repdate)) as Sales5DayAgo,
			(select coalesce(sum(Quantity), 0) from sq_sales where LocationId = l.Id and [Date] = dateadd(day, -6, pm.repdate)) as Sales6DayAgo,
			(select coalesce(sum(Quantity), 0) from sq_forecast where LocationId = l.Id and [Date] > dateadd(day, -7, pm.repdate) and
																							[Date] <= pm.repdate) as ForecastLocationWeek,
			(select coalesce(sum(Quantity), 0) from sq_sales where LocationId = l.Id and [Date] > dateadd(day, -7, pm.repdate) and
																						 [Date] <= pm.repdate) as SalesLocationWeek,
			(select coalesce(sum(Quantity), 0) from sq_forecast where LocationId = l.Id and [Date] >= dateadd(day, -13, pm.repdate) and
																							[Date] < dateadd(day, -6, pm.repdate)) as ForecastLocationWeekAgo,
			(select coalesce(sum(Quantity), 0) from sq_sales where LocationId = l.Id and [Date] >= dateadd(day, -13, pm.repdate) and
																						 [Date] < dateadd(day, -6, pm.repdate)) as SalesLocationWeekAgo,
			(select coalesce(sum(Quantity), 0) from sq_forecast where [Date] > dateadd(day, -7, pm.repdate) and
																	  [Date] <= pm.repdate) as ForecastWeekAllLoc,
			(select coalesce(sum(Quantity), 0) from sq_sales where [Date] > dateadd(day, -7, pm.repdate) and
																   [Date] <= pm.repdate) as SalesWeekAllLoc,
			(select coalesce(sum(Quantity), 0) from sq_forecast where LocationId = l.Id and [Date] > dateadd(day, -28, pm.repdate) and
																							[Date] <= pm.repdate) as ForecastLocation4Week,
			(select coalesce(sum(Quantity), 0) from sq_sales where LocationId = l.Id and [Date] > dateadd(day, -28, pm.repdate) and
																 						 [Date] <= pm.repdate) as SalesLocation4Week,
			(select coalesce(sum(Quantity), 0) from sq_forecast where LocationId = l.Id and [Date] >= dateadd(day, -55, pm.repdate) and
																							[Date] < dateadd(day, -27, pm.repdate)) as ForecastLocation4WeekAgo,
			(select coalesce(sum(Quantity), 0) from sq_sales where LocationId = l.Id and [Date] >= dateadd(day, -55, pm.repdate) and
																						 [Date] < dateadd(day, -27, pm.repdate)) as SalesLocation4WeekAgo,
			(select coalesce(sum(Quantity), 0) from sq_forecast where [Date] > dateadd(day, -28, pm.repdate) and
																	  [Date] <= pm.repdate) as Forecast4WeekAllLoc,
			(select coalesce(sum(Quantity), 0) from sq_sales where [Date] > dateadd(day, -28, pm.repdate) and
																   [Date] <= pm.repdate) as Sales4WeekAllLoc
		from Locations l
		  join StoreFormats sf on sf.Id = l.StoreFormatId
		  join StoreManagementTypes smt on smt.Id = l.ManagementTypeId
		  join Regions city on city.Id = l.RegionId
		  join Regions r on city.ParentId = r.Id,
		  params pm
		where l.IsActive = 1
	),
	sq2 as (
		select 
			case when LFL = 'LFL' and GROUPING(StoreFormat) + GROUPING(LFL) = 0 then -1
				 else (GROUPING(StoreFormat) + GROUPING(LFL)) * -2 end as SortOrder,
			0 as SortCity,
			'Все' as StoreFormat,
			'Все' as RegionName,
			'Все' as CityName,
			case when GROUPING(StoreFormat) + GROUPING(LFL) = 2 then 'Все'
				 when GROUPING(StoreFormat) + GROUPING(LFL) = 0 then StoreFormat + ' ' + LFL
				 when GROUPING(StoreFormat) = 1 then 'Все ' + LFL
				 else null end as ShopName,
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
			sum(ForecastLocationWeek) as ForecastLocationWeek,
			sum(SalesLocationWeek) as SalesLocationWeek,
			sum(ForecastLocationWeekAgo) as ForecastLocationWeekAgo,
			sum(SalesLocationWeekAgo) as SalesLocationWeekAgo,
			max(ForecastWeekAllLoc) as ForecastWeekAllLoc,
			max(SalesWeekAllLoc) as SalesWeekAllLoc,
			sum(ForecastLocation4Week) as ForecastLocation4Week,
			sum(SalesLocation4Week) as SalesLocation4Week,
			sum(ForecastLocation4WeekAgo) as ForecastLocation4WeekAgo,
			sum(SalesLocation4WeekAgo) as SalesLocation4WeekAgo,
			max(Forecast4WeekAllLoc) as Forecast4WeekAllLoc,
			max(Sales4WeekAllLoc) as Sales4WeekAllLoc
		from sq1
		group by cube(StoreFormat, LFL)
		having (GROUPING(LFL) + GROUPING(StoreFormat) in (0, 2)) or (GROUPING(StoreFormat) = 1 and LFL = 'LFL')
		union all
		select 
			case when GROUPING(ShopName) = 1 then 0
				 else 1 end as SortOrder,
			case when GROUPING(CityName) = 1 then 0
				 else 1 end as SortCity,
			StoreFormat,
			RegionName,
			CityName,
			ShopName,			
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
			sum(ForecastLocationWeek) as ForecastLocationWeek,
			sum(SalesLocationWeek) as SalesLocationWeek,
			sum(ForecastLocationWeekAgo) as ForecastLocationWeekAgo,
			sum(SalesLocationWeekAgo) as SalesLocationWeekAgo,
			max(ForecastWeekAllLoc) as ForecastWeekAllLoc,
			max(SalesWeekAllLoc) as SalesWeekAllLoc,
			sum(ForecastLocation4Week) as ForecastLocation4Week,
			sum(SalesLocation4Week) as SalesLocation4Week,
			sum(ForecastLocation4WeekAgo) as ForecastLocation4WeekAgo,
			sum(SalesLocation4WeekAgo) as SalesLocation4WeekAgo,
			max(Forecast4WeekAllLoc) as Forecast4WeekAllLoc,
			max(Sales4WeekAllLoc) as Sales4WeekAllLoc
		from sq1
		group by rollup(RegionName, CityName, ShopName),StoreFormat
		having GROUPING(RegionName) = 0
	 )
	 , 
	sq_osa as (
		select 
		    SortOrder,
			SortCity,
			StoreFormat,
			RegionName,
			coalesce(CityName, 'Все') as CityName,
			coalesce(ShopName, 'Все') as ShopName, 
			case
				when SalesDay = 0 and ForecastDay = 0 then -9999999.25
                else (1 - ForecastDay/(ForecastDay + SalesDay)) 
            end as OsaDay,
			case
				when Sales1DayAgo = 0 and Forecast1DayAgo = 0 then -9999999.25
                else (1 - Forecast1DayAgo/(Forecast1DayAgo + Sales1DayAgo)) 
            end as Osa1DayAgo,
			case
				when Sales2DayAgo = 0 and Forecast2DayAgo = 0 then -9999999.25
                else (1 - Forecast2DayAgo/(Forecast2DayAgo + Sales2DayAgo)) 
            end as Osa2DayAgo,
			case
				when Sales3DayAgo = 0 and Forecast3DayAgo = 0 then -9999999.25
                else (1 - Forecast3DayAgo/(Forecast3DayAgo + Sales3DayAgo)) 
            end as Osa3DayAgo,
			case
				when Sales4DayAgo = 0 and Forecast4DayAgo = 0 then -9999999.25
                else (1 - Forecast4DayAgo/(Forecast4DayAgo + Sales4DayAgo)) 
            end as Osa4DayAgo,
			case 
				when Sales5DayAgo = 0 and Forecast5DayAgo = 0 then -9999999.25
                else (1 - Forecast5DayAgo/(Forecast5DayAgo + Sales5DayAgo)) 
            end as Osa5DayAgo,
			case
				when Sales6DayAgo = 0 and Forecast6DayAgo = 0 then -9999999.25
                else (1 - Forecast6DayAgo/(Forecast6DayAgo + Sales6DayAgo)) 
            end as Osa6DayAgo,
			case 
				when SalesLocationWeek = 0 and ForecastLocationWeek = 0 then -9999999.25
                else (1 - ForecastLocationWeek/(ForecastLocationWeek + SalesLocationWeek)) 
            end as OsaLocationWeek,
			case
				when SalesLocationWeekAgo = 0 and ForecastLocationWeekAgo = 0 then -9999999.25
                else (1 - ForecastLocationWeekAgo/(ForecastLocationWeekAgo + SalesLocationWeekAgo)) 
            end as OsaLocationWeekAgo,
			case
				when SalesWeekAllLoc = 0 and ForecastWeekAllLoc = 0 then -9999999.25
                else (1 - ForecastWeekAllLoc/(ForecastWeekAllLoc + SalesWeekAllLoc)) 
            end as OsaWeekAllLoc,
			case
				when SalesLocation4Week = 0 and ForecastLocation4Week = 0 then -9999999.25
                else (1 - ForecastLocation4Week/(ForecastLocation4Week + SalesLocation4Week)) 
            end as OsaLocation4Week,
			case
				when SalesLocation4WeekAgo = 0 and ForecastLocation4WeekAgo = 0 then -9999999.25 
                else (1 - ForecastLocation4WeekAgo/(ForecastLocation4WeekAgo + SalesLocation4WeekAgo)) 
            end as OsaLocation4WeekAgo,
			case
				when Sales4WeekAllLoc = 0 and Forecast4WeekAllLoc = 0 then -9999999.25
                else (1 - Forecast4WeekAllLoc/(Forecast4WeekAllLoc + Sales4WeekAllLoc)) 
            end as Osa4WeekAllLoc
		from sq2
	)	 

	select
		StoreFormat, 
		RegionName,
		CityName,
		ShopName,
		Osa6DayAgo,
		Osa5DayAgo,
		Osa4DayAgo,
		Osa3DayAgo,
		Osa2DayAgo,
		Osa1DayAgo,
		OsaDay,
		OsaLocationWeek,
		case when OsaLocationWeek = -9999999.25 or OsaLocationWeekAgo = -9999999.25 then -9999999.25
		else OsaLocationWeek - OsaLocationWeekAgo end as OsaDiffLocationWeek,
		case when OsaLocationWeek = -9999999.25 or OsaWeekAllLoc = -9999999.25 then -9999999.25
		else OsaLocationWeek - OsaWeekAllLoc end as OsaDiffWeekAllLoc,
        '' as field1,
		OsaLocation4Week,
		case when OsaLocation4Week = -9999999.25 or OsaLocation4WeekAgo = -9999999.25 then -9999999.25
		else OsaLocation4Week - OsaLocation4WeekAgo end as OsaDiffLocation4Week,
		case when OsaLocation4Week = -9999999.25 or Osa4WeekAllLoc = -9999999.25 then -9999999.25
		else OsaLocation4Week - Osa4WeekAllLoc end as OsaDiff4WeekAllLoc
	from sq_osa
	order by SortOrder,	StoreFormat, RegionName, SortCity, ShopName