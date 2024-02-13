--Creating tables and importing data
create table ball (
id int,
inning int,
over int,
ball int,
batsman varchar,
non_striker varchar,
bowler varchar,
batsman_runs int,
extra_runs int,
total_run int,
is_wicket int,
dismissal_kind varchar,
player_dismissed varchar,
fielder varchar,
extras_type varchar,
batting_team varchar,
bowling_team varchar
);
copy ball from 'C:\Program Files\PostgreSQL\16\data\Data Copy\IPL_ball.csv' CSV header;

Create Table matches(
match_id int primary key,
	city varchar,
	match_date date,
	player_of_match varchar,
	venue varchar,
	neutral_venue boolean,
	team1 varchar,
	team2 varchar,
	toss_winner varchar,
	toss_decision varchar,
	winner varchar,
	result varchar,
	result_margin int,
	eliminator varchar,
	method varchar,
	umpire1 varchar,
	umpire2 varchar
);
copy matches from 'C:\Program Files\PostgreSQL\16\data\Data Copy\IPL_matches.csv' CSV header;



--10 batsmen with the highest strike rate

Select batsman,sum(batsman_runs) As total_runs , count(ball)As balls_faced, (Sum(batsman_runs)/Count(ball)::decimal *100) As strike_rate
from ball
where extras_type != 'wides'
group by batsman
Having count(ball) > 500
order by 4 desc
Limit 10;

--Top 10 batsmen with good average

Select b.batsman,sum(b.batsman_runs) as total_runs,
SUM(b.is_wicket) as total_innings, Sum(b.batsman_runs)/Sum(b.is_wicket)::decimal As average,
Count(distinct(Extract(year from m.match_Date))) as Seasons
From ball b
Join matches m
on b.id = m.match_id
where extras_type = 'NA' 
Group by batsman
Having 
SUM(is_wicket) > 10 AND
Count(distinct(Extract(year from m.match_Date)))>2
Order by 4 desc
Limit 10;



--Hard Hitters
Select b.batsman,sum(b.batsman_runs) As total_runs, 
Sum(Case when b.batsman_runs=4 or b.batsman_runs= 6 then b.batsman_runs else 0 end) As boundary_runs,
(Sum(Case when b.batsman_runs=4 or b.batsman_runs= 6 then b.batsman_runs else 0 end)*1.0/sum(b.batsman_runs))*100 As boundary_percent
from ball b
group by b.batsman
Having 
	sum(b.batsman_runs) > 0 
	ANd Count(distinct b.id) >28

order by 4 desc
Limit 10;

--Good Economy bowlers

--Count(distinct b.over) As overs_bowled didn't use because the number of distinct over is 20, as in from 1 to 20 

Select b.bowler,Sum(b.total_run) As runs_conceded , Count(b.ball)/6 As overs_bowled,
Sum(b.total_run)*1.0/(Count(b.ball)/6) As economy_rate
From ball b
where extras_type = 'NA'
group by b.bowler
Having
	Count(b.ball) > 500
order by 4
Limit 10;

--Top wicket-takers

Select b.bowler,Sum(b.is_wicket) As wickets_taken, Count(b.ball)/6 As overs_bowled,
Count(b.ball)/Sum(b.is_wicket)*1.0 As strike_rate
From ball b
where dismissal_kind Not IN ('run out','obstructing the field','retired hurt')
group by b.bowler
Having
	Count(b.ball) > 500
order by 4
Limit 10;

--Top All-Rounders

Select b.batsman,Round((Sum(batsman_runs)*1.0/Count(ball) *100),2) As strike_rate,
a.bowl_strike_rate
from ball b
inner join
(Select bowler,Round(Count(ball)*1.0/Sum(is_wicket),2) As bowl_strike_rate from ball 
 where dismissal_kind Not IN ('run out','obstructing the field','retired hurt')
group by bowler
Having
	Count(ball) > 300
 ORDER BY
        bowl_strike_rate ASC
) AS a on b.batsman = a.bowler
where extras_type != 'wides'
GROUP BY b.batsman,a.bowl_strike_rate
Having count(b.ball) > 500
Order By 2 desc,3 asc
Limit 10;



--Additional questions
-- 1.) Count of cities:
Select count(distinct city) As unique_cities from matches;

--2.) Deliveries_v02 table
Create Table Deliveries_v02 As
Select *, 
Case when total_run = 0 then 'Dot' 
	when total_run >= 4 then 'Boundary'
	else 'other'
End As ball_result
From ball;

--3) Total number of dots and boundaries:
Select ball_result,Count(ball_result) from Deliveries_v02
group by ball_result;

--4.) query to fetch the total number of boundaries scored by each team q

Select Batting_team As Team, COunt(Case when ball_result= 'Boundary'Then 1 END) As Number_of_Boundaries from deliveries_v02
group by batting_team
Order by 2 desc;

--5.)query to fetch the total number of dot balls bowled by each team;

Select bowling_team As Team, COunt(Case when ball_result ='Dot' Then 1 End) As Number_of_Dots from deliveries_v02
Group by bowling_team
Order by 2 desc;

--6.)query to fetch the total number of dismissals by dismissal kinds where dismissal kind is not NA

Select dismissal_kind,COunt(Case when dismissal_kind !='NA'Then 1 end) As Total_dismissals from deliveries_v02
WHERE dismissal_kind IS NOT NULL
Group by dismissal_kind
order by 2 desc;

--7.)top 5 bowlers who conceded maximum extra runs

Select bowler, Sum(Extra_runs) As Total_extras from deliveries_v02
Group by bowler
Order by 2 desc
limit 5;

--8.) table named deliveries_v03
Create table deliveries_v03 As
Select d.*,m.venue,m.match_date from deliveries_v02 d
Join matches m on
d.id=m.match_id;

--9.)total runs scored for each venue and order it in the descending order of total runs scored. 
Select venue,sum(total_run)As Total_runs from deliveries_v03
Group by venue
Order by total_runs desc;

--10.)year-wise total runs scored at Eden Gardens and order it in the descending order of total runs scored.
Select Extract(year from match_Date)As year,sum(total_run)As Total_runs from deliveries_v03
where venue = 'Eden Gardens'
Group by year
Order by total_runs desc;
