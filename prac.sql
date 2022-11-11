CREATE EXTENSION TABLEFUNC;

DROP TABLE IF EXISTS OLYMPICS_HISTORY;
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY
(
    id          INT,
    name        VARCHAR,
    sex         VARCHAR,
    age         VARCHAR,
    height      VARCHAR,
    weight      VARCHAR,
    team        VARCHAR,
    noc         VARCHAR,
    games       VARCHAR,
    year        INT,
    season      VARCHAR,
    city        VARCHAR,
    sport       VARCHAR,
    event       VARCHAR,
    medal       VARCHAR
);

Drop table if exists noc_regions;
create table if not exists noc_regions
(
	noc VARCHAR,
	region VARCHAR,
	notes VARCHAR
);
select * from olympic_history;
select * from noc_regions;


1.How many olympics games have been held?

select count(distinct games) from olympic_history;

2.Write a SQL query to list down all the Olympic Games held so far.

Select distinct year,season,city from olympic_history order by year asc;

3.SQL query to fetch total no of countries participated in each olympic games.

with all_countries as
(select games,nr.region from olympic_history oh join noc_regions nr on oh.noc=nr.noc 
 group by games,nr.region)
 
 select games,count(1) from all_countries group by games order by games
 
                 OR
				 
select games,count(distinct nr.region) from olympic_history oh join noc_regions nr on oh.noc=nr.noc 
 group by games
 
 4.Which year saw the highest and lowest no of countries participating in olympics

with all_countries as
(select games,count(distinct nr.region) as total_countries from olympic_history oh join noc_regions nr on oh.noc=nr.noc 
 group by games)
 
select distinct
      concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
        from all_countries

5.Which nation has participated in all of the olympic games

with cte1 as(
select count(distinct games) as total,nr.region from olympic_history oh join noc_regions nr on nr.noc=oh.noc group by nr.region
)
select * from cte1 where total=(select count(distinct games) from olympic_history)

6. SQL query to fetch the list of all sports which have been part of every summer olympics.

with cte1 as(
select sport,count(distinct games) as total from olympic_history group by sport)

select * from cte1 where total=(select count(distinct games) from olympic_history where season='Summer')

7.Which Sports were just played only once in the olympics.

with cte1 as(
select sport,count(distinct games) as total from olympic_history group by sport)

select distinct t1.sport,t1.total,oh.games from cte1 as t1 join olympic_history as oh on t1.sport=oh.sport where t1.total=1 

8. Fetch the total no of sports played in each olympic games.

select games,count(distinct sport) as total from olympic_history group by games order by total desc,games asc

9. Fetch oldest athletes to win a gold medal


10. Find the Ratio of male and female athletes participated in all olympic games.

with cte as(
select count(*) as total from olympic_history group by sex)

select concat('1 : ', round(max(total)::decimal/min(total), 2)) as ratio from cte

11. Fetch the top 5 athletes who have won the most gold medals.

with cte as(select name,team,count(*) as total_medal from olympic_history where medal='Gold' group by name,team order by total_medal desc ,name desc,team desc)

select * from cte Limit 10 

12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze)

select name,team,count(*) as total_medal from olympic_history where medal in ('Gold','Silver','Bronze') group by name,team order by total_medal desc

13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

with cte as(
select nr.region,medal as total from olympic_history oh join noc_regions nr on oh.noc=nr.noc where oh.medal <> 'NA' group by nr.region order by total desc
)

select *, DENSE_RANK() over(order by total desc) as rnk from cte 

14. List down total gold, silver and bronze medals won by each country.


select region
		, coalesce(gold, 0) as gold
    	, coalesce(silver, 0) as silver
    	, coalesce(bronze, 0) as bronze
from crosstab('select nr.region, oh.medal,count(1) as total from olympic_history oh join noc_regions nr on oh.noc=nr.noc where oh.medal <> ''NA'' group by nr.region,oh.medal order by 1,2',
					  'values (''Bronze''), (''Gold''), (''Silver'')') 
as new_table(region VARCHAR,Bronze bigint, Gold bigint, Silver bigint)
order by gold desc, silver desc, bronze desc;

15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

select oh.games,nr.region, oh.medal,count(2) as total,count(3) as total_medal from olympic_history oh join noc_regions nr on oh.noc=nr.noc where oh.medal <> 'NA' group by oh.games, nr.region,oh.medal order by 1

select substring(games,1,position(' - ' in games) - 1) as games
        , substring(games,position(' - ' in games) + 3) as country
		, coalesce(gold, 0) as gold
    	, coalesce(silver, 0) as silver
    	, coalesce(bronze, 0) as bronze
from crosstab('select concat(games, '' - '', nr.region) as games, oh.medal,count(1) as total from olympic_history oh join noc_regions nr on oh.noc=nr.noc where oh.medal <> ''NA'' group by oh.games,nr.region,oh.medal order by oh.games',
					  'values (''Bronze''), (''Gold''), (''Silver'')') 
as new_table(games text,Bronze bigint, Gold bigint, Silver bigint)

16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.

with temp as
(
select substring(games,1,position(' - ' in games) - 1) as games
        , substring(games,position(' - ' in games) + 3) as country,
		, coalesce(gold, 0) as gold
    	, coalesce(silver, 0) as silver
    	, coalesce(bronze, 0) as bronze
from crosstab('select concat(games, '' - '', nr.region) as games, oh.medal,count(1) as total from olympic_history oh join noc_regions nr on oh.noc=nr.noc where oh.medal <> ''NA'' group by oh.games,nr.region,oh.medal order by oh.games',
					  'values (''Bronze''), (''Gold''), (''Silver'')') 
as new_table(games text,Bronze bigint, Gold bigint, Silver bigint)
)
select distinct games
    	, concat(first_value(country) over(partition by games order by gold desc)
    			, ' - '
    			, first_value(gold) over(partition by games order by gold desc)) as Max_Gold
    	, concat(first_value(country) over(partition by games order by silver desc)
    			, ' - '
    			, first_value(silver) over(partition by games order by silver desc)) as Max_Silver
    	, concat(first_value(country) over(partition by games order by bronze desc)
    			, ' - '
    			, first_value(bronze) over(partition by games order by bronze desc)) as Max_Bronze
    from temp
    order by games

17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

with temp as
(
select substring(games,1,position(' - ' in games) - 1) as games
        , substring(games,position(' - ' in games) + 3) as country
		,(coalesce(gold, 0)+coalesce(silver, 0)+coalesce(bronze, 0)) as total
		, coalesce(gold, 0) as gold
    	, coalesce(silver, 0) as silver
    	, coalesce(bronze, 0) as bronze
from crosstab('select concat(games, '' - '', nr.region) as games, oh.medal,count(1) as total from olympic_history oh join noc_regions nr on oh.noc=nr.noc where oh.medal <> ''NA'' group by oh.games,nr.region,oh.medal order by oh.games',
					  'values (''Bronze''), (''Gold''), (''Silver'')') 
as new_table(games text,Bronze bigint, Gold bigint, Silver bigint)
)
select distinct games
    	, concat(first_value(country) over(partition by games order by gold desc)
    			, ' - '
    			, first_value(gold) over(partition by games order by gold desc)) as Max_Gold
    	, concat(first_value(country) over(partition by games order by silver desc)
    			, ' - '
    			, first_value(silver) over(partition by games order by silver desc)) as Max_Silver
    	, concat(first_value(country) over(partition by games order by bronze desc)
    			, ' - '
    			, first_value(bronze) over(partition by games order by bronze desc)) as Max_Bronze
		, concat(first_value(country) over(partition by games order by total desc)
    			, ' - '
    			, first_value(total) over(partition by games order by total desc)) as Max_Medals
    from temp
    order by games

18. Which countries have never won gold medal but have won silver/bronze medals?

select * from(
		select country
				, coalesce(gold, 0) as gold
				, coalesce(silver, 0) as silver
				, coalesce(bronze, 0) as bronze
		from crosstab('select nr.region, oh.medal,count(1) as total from olympic_history oh join noc_regions nr on oh.noc=nr.noc where oh.medal <> ''NA'' group by nr.region,oh.medal order by nr.region,oh.medal',
							  'values (''Bronze''), (''Gold''), (''Silver'')') 
		as new_table(country varchar,Bronze bigint, Gold bigint, Silver bigint)) as final_table
where gold=0 and(silver=0 or bronze=0)
order by gold desc nulls last, silver desc nulls last, bronze desc nulls last;

19. In which Sport/event, India has won highest medals.

with cte as(
select team,sport,count(medal) as total_medals from olympic_history where team='India' and medal<>'NA' group by sport,team
)
select distinct first_value(sport) over(partition by team order by total_medals desc) as sport,
	   first_value(total_medals) over(partition by team order by total_medals desc)
	   from cte
	   
20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

select team,sport,count(medal) as total_medals,games from olympic_history where team='India' and medal<>'NA' and sport='Hockey' group by sport,team,games order by total_medals desc


	   
	