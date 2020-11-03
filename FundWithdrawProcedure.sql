 --资金转入
use YStore
go
if exists (select * from sysobjects where name = 'sys_convertin')
  drop proc sys_convertin
go
create procedure sys_convertin
@hid varchar(100),@imoney float, @pid varchar(2),@cuid varchar(4)  
as
begin
--变量定义
declare @iid2 varchar(8),@iprice float   ,@iamount  int  ,@remark varchar(100) ,@place varchar(2)
declare @iname varchar(30) ,@iunit  varchar(10),@sname  varchar(100)  
declare @bid varchar(4),@cname  varchar(100)

 --赋值（有变化的）

--变量赋固定值

declare @p_date date
select @p_date=wdate from wstatus
 declare @errorcode int, @errormsg varchar(255), @starttran char
  select @errorcode = 0, @errormsg = '', @starttran = '0'
   --1：判断状态是否为0 
 declare @status varchar(2)
 select @status=status from wstatus
if @status <>0
 begin
   select @errorcode = -1, @errormsg = '状态异常不为0，不可进行操作'
   goto exit_end
  end
--1.开始事务
begin tran  --事务定义begin tran
   select @starttran = '1'
--1.1:流水变更
insert into statement select '0001' as bid ,@p_date as wdate,@hid as hid, ''as iid2, '' as iname ,0 as iprice ,''as iunit,0 as iamount,@imoney as imoney,'' as sname ,'' as cname ,@pid as pid ,@cuid as cuid,'' as remark,'' as place,getdate() as oprdate
if ( @@error <> 0 )
    begin
       select @errorcode = -1, @errormsg = '流水表更新失败'
       goto exit_end
	  end  
--1.2：资金变更
update wbank
set trbalance = trbalance+@imoney
where wdate = convert (varchar(100), @p_date,23) and cuid=@cuid 
if ( @@error <> 0 )
    begin
       select @errorcode = -1, @errormsg = '资金表更新失败'
       goto exit_end
	  end 		
	

---因为有错误都到goto到了回滚，没问题就提交事务
  select errorcode = 0 , errormsg = '资金转入成功'
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
end
go

--execute sys_convertin '000001','100','2','0'

