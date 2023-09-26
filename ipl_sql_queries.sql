-- created a view for future use
create view joined as select * from ipl.balls t1 left join ipl.matches t2 on t1.id1=t2.id;
use ipl;
-------------------------------------------------------------------------------------------------------------------
-- 1) Top 5 batsman in specific season
SELECT batter,sum(batsman_run) as runs FROM joined
where season=2016 group by batter order by runs desc limit 5;
---------------------------------------------------------------------------------------------------------------------
-- 2) Top 5 bowler(wicket Taken) in specific season
SELECT bowler,sum(isWicketDelivery) as wicket FROM joined
where season=2016  and kind not in ('run out','retired hurt','retired out','obstructing the field') 
group by bowler order by wicket desc limit 5;
---------------------------------------------------------------------------------------------------------------------------
-- 3) Bowlers with most five wicket hauls in Indian Premier League
select bowler,count(*) from
(select bowler,count(*),sum(isWicketDelivery) 
from ipl.balls group by bowler,id1 having sum(isWicketDelivery)>=5) t 
group by t.bowler order by count(*) desc limit 5;
------------------------------------------------------------------------------------------------------------------------------------
-- 4) Top 5 team score
select BattingTeam,sum(total_run) as runs FROM joined
where season=2016 group by t1.id,t1.BattingTeam order by runs desc limit 5;
----------------------------------------------------------------------------------------------------------------------------
-- 5) Top 5 individual score
select batter,sum(batsman_run) as runs FROM joined
where season=2016 group by t1.id,t1.batter order by runs desc limit 5;
------------------------------------------------------------------------------------------------------------------------------------
-- 6) Players with most centuries in Indian Premier League
select batter,count(*) from 
(SELECT batter,sum(batsman_run) as runs 
FROM ipl.balls group by id1,batter having runs > 99) t1 
group by batter order by count(*) desc limit 5;
-----------------------------------------------------------------------------------------------------------------------------------
-- 7) Number of half centuries of specific batter
select count(*) from (SELECT id,sum(batsman_run) as runs 
FROM ipl.balls where batter='V Kohli' group by id having runs > 49) t1;
-----------------------------------------------------------------------------------------------------------------------------
-- 8) Number of centuries of specific batter
select count(*) from (SELECT id,sum(batsman_run) as runs 
FROM ipl.balls where batter='V Kohli' group by id having runs > 99) t1;
------------------------------------------------------------------------------------------------------------------------
-- 9) point table
SELECT team, 
       COUNT(*) AS matches_played,
       SUM(CASE WHEN team = WinningTeam THEN 1 ELSE 0 END) AS matches_won
FROM
(
    SELECT team1 AS team, WinningTeam
    FROM ipl.matches
    UNION ALL
    SELECT team2 AS team, WinningTeam
    FROM ipl.matches
) AS subquery
GROUP BY team;
-----------------------------------------------------------------------------------------------------------------------
-- 10) specific batsman vs specific bowler
SELECT batter,bowler,sum(isWicketDelivery) as 'out',sum(batsman_run) as 'Runs',
 (sum(total_run)/count(*))*100 as strike_rate 
FROM ipl.balls where batter = 'V kohli' and bowler = 'Mohammed Shami';
----------------------------------------------------------------------------------------------------------------------
-- 11) top 5 run scorer of each  teams
select * from (SELECT BattingTeam,batter,sum(batsman_run),
dense_rank() over(partition by BattingTeam order by sum(batsman_run) desc) as 'rank' 
FROM ipl.balls group by BattingTeam,batter) t
where t.rank<6;
--------------------------------------------------------------------------------------------------------------------------
-- 12)  innings taken by specific batter to complete specific total run
select * from (select row_number() over(partition by batter order by id1) as id,batter,sum(batsman_run) as Runs,id1,
sum(sum(batsman_run)) over(partition by batter rows between unbounded preceding and current row) as cum_sum
from ipl.balls group by id1,batter) t
where batter = 'V kohli' and cum_sum between 2980 and 3120;

------------------------------------------------------------------------------------------------------------------------------
-- 13) Players with most sixes in Indian Premier League
select batter,count(*) from ipl.balls 
where batsman_run=6 group by batter order by count(*) desc limit 5;

----------------------------------------------------------------------------------------------------------------------------
-- 14) Most madiens bowled in Indian Premier League
select bowler,count(*) from
(select bowler,count(*),sum(total_run) from ipl.balls 
group by bowler,id1,overs having sum(total_run)=0) t 
group by t.bowler order by count(*) desc limit 5;
--------------------------------------------------------------------------------------------------------------------------

-- 15) Batsman dismissed by Harbhajan most time in IPL
select batter,count(*) from ipl.balls where bowler='SL Malinga' and isWicketDelivery=1 
group by batter order by count(*) desc limit 5;
--------------------------------------------------------------------------------------------------------------------
-- 16) Stadium wise matches hosted in IPL
select Venue,city,count(*) from ipl.matches group by Venue,city order by count(*) desc;

----------------------------------------------------------------------------------------------------------------------------
-- 17) Team , Season wise boundaries in IPL
select BattingTeam,
sum(case when batsman_run=4 then 1 else 0 end) as fours,
sum(case when batsman_run=6 then 1 else 0 end) as sixes 
from ipl.balls group by battingteam order by sixes desc;

select season,
sum(case when batsman_run=4 then 1 else 0 end) as fours,
sum(case when batsman_run=6 then 1 else 0 end) as sixes 
from joined group by season order by sixes desc;
-------------------------------------------------------------------------------------------------------------------------------
-- 18) Players who has taken most catches in IPL
select fielders_involved,count(*) from ipl.balls 
where kind='caught' group by fielders_involved order by count(*) desc limit 10;
---------------------------------------------------------------------------------------------------------------------------
-- 19) Players with most man-of-the-matches in IPL
select player_of_match,count(*) from ipl.matches group by player_of_match order by count(*) desc limit 10;
------------------------------------------------------------------------------------------------------------------------
-- 20) Orange Cap/Purple cap holders season wise in IPL
with orange_cap as (SELECT season, batter
FROM (
	SELECT season, batter, ROW_NUMBER() OVER (PARTITION BY season ORDER BY sum(batsman_run) DESC) AS rn
	FROM joined group by season,batter
    ) AS subquery
WHERE rn = 1),
purple_cap as(    
SELECT season, bowler
FROM (
	SELECT season, bowler, ROW_NUMBER() OVER (PARTITION BY season ORDER BY sum(isWicketDelivery) DESC) AS rn
	FROM joined group by season,bowler
    ) AS subquery
WHERE rn = 1)
SELECT s.season, o.batter AS orange_cap_holder, p.bowler AS purple_cap_holder
FROM orange_cap o
JOIN purple_cap p ON o.season = p.season
JOIN (SELECT DISTINCT season FROM joined) s ON o.season = s.season;
------------------------------------------------------------------------------------------------------------------------
-- 21) number of 200+ score per team
select battingteam,count(*) from 
(SELECT battingteam,count(*) FROM ipl.balls group by BattingTeam,id1 having sum(total_run)>=200) t 
group by t.battingteam order by count(*) desc;
-------------------------------------------------------------------------------------------------------------------------
-- 22) number of finals played by team
select t.team1,count(*) from (select team1 from ipl.matches where MatchNumber='Final'
union all
select team2 from ipl.matches where MatchNumber='Final') t group by t.team1 order by count(*) desc;
-------------------------------------------------------------------------------------------------------------------------
-- 23) strike rate of specific batsman in specific overs
SELECT (sum(batsman_run)/count(*))*100 as strike_rate 
FROM (select * from ipl.balls where overs between 1 and 6) t
where batter='V kohli';
----------------------------------------------------------------------------------------------------------------------
-- Highest/Lowest scores of each season by wich team
select season,BattingTeam,max_score from 
	(select season,BattingTeam,sum(total_run) as max_score, 
	rank() over(partition by season order by sum(total_run) desc) as ranks 
	from joined group by season,id1,battingteam) t
where ranks =1;

select season,BattingTeam,max_score from 
	(select season,BattingTeam,sum(total_run) as max_score, 
	rank() over(partition by season order by sum(total_run) asc) as ranks 
	from joined group by season,id1,battingteam) t
where ranks =1;
------------------------------------------------------------------------------------------------------------------------
-- Highest run scorer and highest wicket taker team of each season
select season,BattingTeam,total_runs from 
	(select season,BattingTeam,sum(total_run) as total_runs, 
	rank() over(partition by season order by sum(total_run) asc) as ranks 
	from joined group by season,battingteam) t
where ranks =1;

select season,BattingTeam,total_wickets from 
	(select season,BattingTeam,sum(isWicketDelivery) as total_wickets, 
	rank() over(partition by season order by sum(total_run) asc) as ranks 
	from joined group by season,battingteam) t
where ranks =1;
------------------------------------------------------------------------------------------------------------------
-- In which overs given bowler takes most wicktes
select overs,sum(isWicketDelivery) as wicket_taken 
from ipl.balls where bowler='SL Malinga' group by overs order by wicket_taken desc;
---------------------------------------------------------------------------------------------------------------
-- How toss win impacts the match win (which team utilized the toss win most)
select team,matches_played,toss_won,match_won,match_won_with_toss_win,(match_won_with_toss_win/toss_won)*100 as percentage 
from 
(select tosswinner,count(*) as toss_won, sum(case when tosswinner=winningteam then 1 else 0 end) as match_won_with_toss_win from ipl.matches group by TossWinner) t1 join 
(select WinningTeam,count(*) as match_won from ipl.matches group by WinningTeam) t2 on t1.tosswinner=t2.winningteam
join 
( select team,count(*) as matches_played from (SELECT team1 AS team, WinningTeam
    FROM ipl.matches
    UNION ALL
    SELECT team2 AS team, WinningTeam
    FROM ipl.matches) t group by team) t3
on t1.tosswinner=t3.team order by percentage desc;


-- Fast Vs Spin in Rajiv Gandhi International Stadium
-- Which Player has played for most number of Teams in IPL
-- Most matches captained by players
-- Players involved in most IPL match victories

-- Matches Captained and won by Steve Smith in IPL

-- lowest economy rate
-- toss effect on win





































