-- =============================================
-- Author:		<Yiwen Wu>
-- Create date: <2019-07-06>
-- Description:	<商品销售处理存储过程>
-- =============================================
use YStore
go
if exists (select * from sysobjects where name = 'sys_sell')
  drop proc sys_sell
go
create procedure sys_sell
@p_hid varchar(8)  ,--经手人id
@p_iid2 varchar(8),--商品id
@p_iprice float,--商品卖出价格
@p_iamount  int ,--商品交易数量
@p_cid varchar(100) ,--客户id
@p_place varchar(2),--存放位置
@p_pid  varchar(2),   --支付方式
@p_cuid varchar(4)--币种类型
as
declare @iname  varchar(30) ,@iunit  varchar(10),@imoney float  
declare @cname  varchar(100) ,@lastnum int     

--变量取值
select @iname=iname from witem where iid2=@p_iid2
select @iunit =iunit from witem where iid2=@p_iid2
select @imoney = @p_iamount * @p_iprice 
select @cname=cname from wclient where cid=@p_cid
select @lastnum=num from wstorage where iid2=@p_iid2
--变量赋固定值
 declare @p_date date
 select @p_date=wdate from wstatus  --定义购买日期
 declare @p_num int 
 select @p_num=num  from wstorage where iid2=@p_iid2 and place=@p_place
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
 declare @status varchar(2)
 select @status=status from wstatus
if @status <>0
 begin
   select @errorcode = -1, @errormsg = '状态异常不为0，不可进行操作'
   goto exit_end
  end
--1.销售商品不在商品名册里
if not exists (select * from wstorage where iid2=@p_iid2 and place=@p_place)
begin
   select @errorcode = -1, @errormsg = '无此商品'
    goto exit_end
  end
--2.库存不足不可销售
if (@p_iamount>@p_num) 
begin
   select @errorcode = -1, @errormsg = '该地域库存数量不足'
    goto exit_end
  end
--3.开始事务
begin tran  --事务定义begin tran
   select @starttran = '1'
--3.1：生成流水

---1.流水生成
  insert into statement select '0102' as bid ,@p_date as wdate,@p_hid as hid, @p_iid2 as iid2, @iname as iname ,@p_iprice as iprice ,@iunit as iunit,@p_iamount as iamount,@imoney as imoney,
  '' as sname ,@cname as cname ,@p_pid as pid ,@p_cuid as cuid,@p_cid as sid,@p_place as place,getdate() as oprdate
  if ( @@error <> 0 )
     begin
       select @errorcode = -1, @errormsg = '流水插入失败'
       goto exit_end
     end 

--2.库存更新	
		update wstorage
		set num=num-@p_iamount,cost=cost-@imoney
		where iid2=@p_iid2 and place=@p_place
		
        if ( @@error <> 0 )
          begin
           select @errorcode = -1, @errormsg = '新入商品更新失败'
           goto exit_end
	      end 
	  
--3.资金的变化
update wbank
set trbalance = trbalance+@imoney
where wdate = convert (date, @p_date,23) and cuid=@p_cuid 
if ( @@error <> 0 )
      begin
       select @errorcode = -1, @errormsg = '资金更新失败'
       goto exit_end
	  end  
---因为有错误都到goto到了回滚，没问题就提交事务
  select errorcode = 0 , errormsg = '销售成功'
  commit tran
   
exit_end:
  if ( @errorcode <> 0 or @@error<>0 )
  begin
     if @starttran = '1'
      rollback
      select errorcode = @errorcode, errormsg = @errormsg
   -- return -1
  end
   -- return 0
   
go



--execute sys_sell '00000002','0907',500,1,'0000','2', '2','0'