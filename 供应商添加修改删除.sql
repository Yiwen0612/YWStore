-- =============================================
-- Author:		<Yiwen Wu>
-- Create date: <2019-07-06>
-- Description:	<供应商添加存储过程>
-- =============================================
use YStore
go
if exists (select * from sysobjects where name = 'sys_supplieradd')
  drop proc sys_supplieradd
go
create procedure sys_supplieradd
  @p_hid varchar(8)  ,--经手人id
  @p_sname  varchar(100),--供应商名称
  @p_sid varchar(8),--供应商id
  @p_addr varchar(100),--地址
  @p_stel varchar(11),--电话
  @p_spre varchar(100) --喜好
as
begin
--变量定义
declare @remark varchar(100) 
 declare @p_date date
select @p_date=wdate from wstatus     
--赋值（有变化的）

--变量取值
select @remark=@p_sid+'，'+@p_addr+'，'+@p_stel+'，'+@p_spre
--变量赋固定值
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

--1.判断：如果该供应商已经存在，则无需添加
if exists (select sname from wsupplier where sname=@p_sname)
begin
   select @errorcode = -1, @errormsg = '该供应商已存在'
    goto exit_end
  end
--2.判断：如果供应商编码已被注册，则请换一个输入
if exists (select sid from wsupplier where sid=@p_sid)
begin
   select @errorcode = -1, @errormsg = '供应商编码已被注册,id需大于'+max(sid)from wsupplier
    goto exit_end
  end
--3.开始事务
begin tran  --事务定义begin tran
   select @starttran = '1'
--3.1生成流水

	insert into statement select '0301' as bid ,@p_date as wdate,@p_hid as hid, '' as iid2, '' as iname ,0 as iprice ,'' as iunit,0 as iamount,0 as imoney,
	@p_sname as sname ,'' as cname ,'' as pid ,'' as cuid,@remark as sinfo,'' as place,getdate() as oprdate
	  if ( @@error <> 0 )
     begin
       select @errorcode = -1, @errormsg = '流水插入失败'
       goto exit_end
     end 
--3.2 供应商字典更新
	insert into wsupplier
    select @p_sid,@p_sname,@p_addr,@p_stel,@p_spre	
    if ( @@error <> 0 )
      begin
       select @errorcode = -1, @errormsg = '供应商表更新失败'
       goto exit_end
	  end  
---因为有错误都到goto到了回滚，没问题就提交事务
  select errorcode = 0 , errormsg = '供应商添加成功'
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
   end
go

execute sys_supplieradd '00000001','大型梯田1','3792','湖北路199号','13237179998','土豆2' 

------------------------------------------
--修改
use YStore
go
if exists (select * from sysobjects where name = 'sys_suppliermod')
  drop proc sys_suppliermod
go
create procedure sys_suppliermod
@p_hid varchar(8),
@p_sid varchar(100),
@p_sname varchar(100),
@p_addr varchar(100),
@p_stel varchar(100),
@p_spre varchar(100)
as
begin
--变量定义
declare @remark varchar(100)  
declare @p_date date
select @p_date=wdate from wstatus  
--变量取值
select @remark=@p_sid+'，'+@p_addr+'，'+@p_stel+'，'+@p_spre

declare @sname varchar(100)
select @sname=sname from wsupplier where sid=@p_sid


declare @addr varchar(100)
select @addr=saddr from wsupplier where sid=@p_sid


declare @stel varchar(100)
select @stel=stel from wsupplier where sid=@p_sid


declare @spre varchar(100)
select @spre=spre from wsupplier where sid=@p_sid

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
--1.如果录入供应商id不存在，则不可修改需要先添加
if not exists (select sid from wsupplier where sid =@p_sid)
      begin
       select @errorcode = -1, @errormsg = '商品明细表中不存在此供应商'
       goto exit_end
	  end 

--2.判断：如果录入跟存在的供应商信息一样
if @p_sname is not null and @sname<>@p_sname
     begin
       select @errorcode = -1, @errormsg = '商品明细表中不存在此供应商'
       goto exit_end
	  end 
if @p_addr is not null and @addr<>@p_addr
     begin
       select @errorcode = -1, @errormsg = '商品明细表中不存在此供应商'
       goto exit_end
	  end 
if @p_sname is not null and @sname<>@p_sname
     begin
       select @errorcode = -1, @errormsg = '商品明细表中不存在此供应商'
       goto exit_end
	  end 
if @p_sname is not null and @sname<>@p_sname
     begin
       select @errorcode = -1, @errormsg = '商品明细表中不存在此供应商'
       goto exit_end
	  end 

--2.开始事务
begin tran  --事务定义begin tran
	select @starttran = '1'
--2.1:生成流水
	insert into statement select '0302' as bid ,@p_date as wdate,@p_hid as hid, '' as iid2, '' as iname ,0 as iprice ,'' as iunit,0 as iamount,0 as imoney,
	@sname as sname ,'' as cname ,'' as pid ,'' as cuid,@remark as sinfo,'' as place,getdate() as oprdate
	if ( @@error <> 0 )
      begin
       select @errorcode = -1, @errormsg = '流水插入失败'
       goto exit_end
	  end 

--2.2：更新供应商明细表
if (@sname is not null)
	update wsupplier set  sname=@sname where  sid=@p_sid 
if (@addr is not null)
	update wsupplier set  saddr=@addr where  sid=@p_sid 
if (@stel is not null)
	update wsupplier set  stel=@stel where  sid=@p_sid 
if (@spre is not null)
	update wsupplier set  spre=@spre where  sid=@p_sid 
---因为有错误都到goto到了回滚，没问题就提交事务
  select errorcode = 0 , errormsg = '供应商修改成功'
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
   end
go

--execute sys_suppliermod  '00000001','3792','','','13237179998',''

----------------------------------------------
--删除
use YStore
go
if exists (select * from sysobjects where name = 'sys_suppliercut')
  drop proc sys_suppliercut
go
create procedure sys_suppliercut 
 @p_hid varchar(8) ,--经手人id
 @p_sid varchar(8)--商品id
 as
 begin
--变量变量
declare  @sname  varchar(100)   
 declare @p_date date
select @p_date=wdate from wstatus  

--赋值（有变化的）

select @sname=sname from wsupplier where sid=@p_sid
--变量赋固定值
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
   select @errorcode = -1, @errormsg = '状态异常不为0,供应商删除失败'
   goto exit_end
  end
--1.判断：如果该供应商不存在，则无需删除
if not exists (select sname from wsupplier where sid=@p_sid)
begin
   select @errorcode = -1, @errormsg = '该供应商不存在'
    goto exit_end
  end

--2.开始事务
begin tran
   select @starttran = '1'
--2.1：生成流水
insert into statement select '0303' as bid ,@p_date as wdate,@p_hid as hid, '' as iid2, ''as iname ,0 as iprice ,'' as iunit,0 as iamount,0 as imoney,
@sname as sname ,'' as cname ,'' as pid ,'' as cuid,'' as sinfo,'' as place,getdate() as oprdate
 if ( @@error <> 0 )
     begin
       select @errorcode = -1, @errormsg = '流水插入失败'
       goto exit_end
     end		
--2.1:供应商进行更新	
delete from wsupplier where sid=@p_sid
 if ( @@error <> 0 )
     begin
       select @errorcode = -1, @errormsg = '供应商删除失败'
       goto exit_end
     end				
	
---因为有错误都到goto到了回滚，没问题就提交事务
  select errorcode = 0 , errormsg = '供应商删除成功'
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
   end
go

--execute sys_suppliercut '00000001','0109'
--select * from wsupplier where sid='3792'