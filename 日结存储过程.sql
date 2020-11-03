-- =============================================
-- Author:		<Yiwen Wu>
-- Create date: <2019-07-06>
-- Description:	<日结存储过程>
-- =============================================
use YStore
go
if exists (select * from sysobjects where name = 'sys_end')
  drop proc sys_end
go
create procedure sys_end 
@p_hid varchar(8)--经手人id
as
declare @cut as float,@add as float,@wdate date,@cuid varchar(2),@bankm float,@status varchar(2)
declare @statuscnt int
declare @errorcode int, @errormsg varchar(255), @starttran char
select @errorcode = 0, @errormsg = '', @starttran = '0'
------
declare @right int

declare @p_erromsg varchar(100) 
execute @right= inside_get_handler @p_hid,@p_erromsg  output
if @right=-1
 begin
   select @errorcode = -1, @errormsg = @p_erromsg
   goto exit_end
  end
 --1：判断状态是否为0 
 select @status=status ,@wdate=wdate from wstatus
if @status <>0
 begin
   select @errorcode = -1, @errormsg = '状态异常不为0，不可日结'
   goto exit_end
  end
--2.将状态修改为，正在结账，防止结账期间有业务发生
if @status=0
update wstatus
set status='4'

--3.判断资金知否平衡
--3.1：
select @cuid=0
select @bankm= trbalance-yrbalance from wbank where convert(varchar(100),wdate,23)=@wdate and cuid=@cuid
select @add= sum(imoney) from statement where bid in ('0001','0102') and convert(varchar(100),wdate,23)=@wdate  and cuid=@cuid
select @cut= sum(imoney) from statement where bid in ('0002','0101') and convert(varchar(100),wdate,23)=@wdate and cuid=@cuid
--3.2：比较
if ((@add-@cut)<>@bankm)
 begin
   
   select @errorcode = -1, @errormsg = '资金不平衡，日结失败。'
   goto exit_end
  end
--4：仓库物品核对
if object_id('tempdb..#templs') is not null
 begin 
 drop table #templs
 end
 
 if object_id('tempdb..#temp01') is not null
 begin 
 drop table #temp01
 end
select iid2,bid,iamount,place into #templs from statement
		where iamount <>0
update #templs set iamount=iamount*(-1) where bid='0102'			
				
select iid2,sum(iamount)as lsnum,place ,0 as kcnum ,0 as ce into #temp01 from #templs group by iid2,place
	update #temp01
	set kcnum=b.num-b.lastnum
	from #temp01 a,wstorage b
	where a.iid2=b.iid2 and a.place=b.place
update #temp01
	set ce=kcnum-lsnum
					
if exists (select ce from #temp01 where ce<>0 )
   begin
	select @errorcode = -1, @errormsg = '库存不平衡，日结失败。'							
    goto exit_end
				
	end		

--5.若平衡，开始事务
begin tran  --事务定义begin tran
   select @starttran = '1'
--3.1:状态表变更
update wstatus
set status='2'
if ( @@error <> 0 )
    begin
       select @errorcode = -1, @errormsg = '状态更新失败'
       goto exit_end
	  end  
---因为有错误都到goto到了回滚，没问题就提交事务
  select errorcode = 0 , errormsg = '日结成功'
  commit tran
   
exit_end:
  if ( @errorcode <> 0 or @@error<>0 )
  begin
     if @starttran = '1'
      rollback
      select errorcode = @errorcode, errormsg = @errormsg
   return -1
  end
   return 0


go

--execute sys_end '00001' 
--update wstatus set status='0'
--select * from wstatus 
--