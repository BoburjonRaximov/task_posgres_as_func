"1"
create or replace function get_branch() 
	returns table (
		names varchar,
		num int
	) 
	language 'plpgsql'
as $$
begin
	return query 
		select b.name, count(p.id * bt.quantity) :: integer as num
    from branches as b
        join branch_transaction as bt on b.id = bt.branch_id
    join products as p on p.id = bt.product_id
    group by b.id
    order by num desc;
end;$$;

"2"
create or replace function get_sum() 
	returns table (
		names varchar,
		num int
	) 
	language 'plpgsql'
as $$
begin
	return query 
	SELECT  b.name, SUM(p.price*bt.quantity) ::integer total_sum
            FROM branches AS b
                  JOIN branch_transaction AS bt ON b.id = bt.branch_id
      JOIN products AS p ON p.id = bt.product_id
      GROUP BY  b.id
      ORDER BY total_sum;
end;$$;

"3"
create or replace function get_product() 
	returns table (
		names varchar,
		num int
	) 
	language 'plpgsql'
as $$
begin
	return query 
	select p.name, count(bt.id)::integer as numbers
    from products as p 
        join branch_transaction as bt on p.id = bt.product_id
    group by p.id
    order by numbers;
end;$$;

"4"
create or replace function get_category() 
	returns table (
		names varchar,
		num int
	) 
	language 'plpgsql'
as $$
begin
	return query 
	select c.name, count(bt.product_id) :: integer as numbers 
    from categories as c
    join products as p on p.category_id = c.id 
        left join branch_transaction as bt on p.id = bt.product_id
    group by c.name
    order by numbers;
end;$$;

"5"
create or replace function get_transaction() 
	returns table (
		branch_names varchar,
        category_name varchar,
		tr_soni int
	) 
	language 'plpgsql'
as $$
begin
	return query 
	select b.name, c.name, count(bt.id) :: integer as tr_soni
    from branch_transaction as bt
         inner join branches as b on b.id = bt.branch_id
         inner join products as p on p.id = bt.product_id
         left join categories as c on c.id = p.category_id
    group by b.name , c.name
    order by tr_soni;
end;$$;

"3-procedure"
create or replace procedure transfer(
   branch int, 
   product int,
   amount int
)
language plpgsql    
as $$
begin
   if exists (select from branch_products where quantity > amount) THEN
    update branch_products 
    set quantity = quantity - amount 
    where branch_id = branch AND product_id = product ;

	INSERT INTO branch_pr_transaction(id, branch_id, product_id, type,quantity,created_at)
	VALUES((SELECT MAX(id)+1 FROM public.branch_pr_transaction), branch, product, 'minus', amount, current_timestamp); 
    commit;
	ELSE
	raise notice 'quantity yetarli emas';
	end if;
end;$$;


"4-array_agg"
select b.name, array_agg(c.name) categories 
    from branch_transaction as bt
         inner join branches as b on b.id = bt.branch_id
         inner join products as p on p.id = bt.product_id
         left join categories as c on c.id = p.category_id
    group by b.name;

"5 -function"
create or replace function top() 
	returns table (
		branch_names varchar,
        category_name int,
		status text
	) 
	language 'plpgsql'
as $$
begin
	return query
	select p.name, bt.quantity,
	CASE WHEN bt.quantity <= 50 AND bt.type = 'minus' THEN 'yangi'
		WHEN bt.quantity > 50 AND bt.quantity <= 100 AND bt.type = 'minus' THEN 'xit'
		WHEN bt.quantity > 100 AND bt.type = 'minus' THEN 'top'
		ELSE 'Sotilmagan'
	END yangi_xit_top
	from branch_pr_transaction as bt
	inner join products as p on p.id = bt.product_id
	group by p.name, bt.quantity, bt.type;
end;$$;

