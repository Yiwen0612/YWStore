-- =============================================
-- Author:		<Yiwen Wu>
-- Create date: <2019-07-06>
-- Description:	<��Ӧ����Ӵ洢����>
-- =============================================
use YStore
go
if exists (select * from sysobjects where name = 'sys_supplieradd')
  drop proc sys_supplieradd
go
create procedure sys_supplieradd
  @p_hid varchar(8)  ,--������id
  @p_sname  varchar(100),--��Ӧ������
  @p_sid varchar(8),--��Ӧ��id
  @p_addr varchar(100),--��ַ
  @p_stel varchar(11),--�绰
  @p_spre varchar(100) --ϲ��
as
begin
--��������
declare @remark varchar(100) 
 declare @p_date date
select @p_date=wdate from wstatus     
--��ֵ���б仯�ģ�

--����ȡֵ
select @remark=@p_sid+'��'+@p_addr+'��'+@p_stel+'��'+@p_spre
--�������̶�ֵ
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
   --1���ж�״̬�Ƿ�Ϊ0 
 declare @status varchar(2)
 select @status=status from wstatus
if @status <>0
 begin
   select @errorcode = -1, @errormsg = '״̬�쳣��Ϊ0�����ɽ��в���'
   goto exit_end
  end

--1.�жϣ�����ù�Ӧ���Ѿ����ڣ����������
if exists (select sname from wsupplier where sname=@p_sname)
begin
   select @errorcode = -1, @errormsg = '�ù�Ӧ���Ѵ���'
    goto exit_end
  end
--2.�жϣ������Ӧ�̱����ѱ�ע�ᣬ���뻻һ������
if exists (select sid from wsupplier where sid=@p_sid)
begin
   select @errorcode = -1, @errormsg = '��Ӧ�̱����ѱ�ע��,id�����'+max(sid)from wsupplier
    goto exit_end
  end
--3.��ʼ����
begin tran  --������begin tran
   select @starttran = '1'
--3.1������ˮ

	insert into statement select '0301' as bid ,@p_date as wdate,@p_hid as hid, '' as iid2, '' as iname ,0 as iprice ,'' as iunit,0 as iamount,0 as imoney,
	@p_sname as sname ,'' as cname ,'' as pid ,'' as cuid,@remark as sinfo,'' as place,getdate() as oprdate
	  if ( @@error <> 0 )
     begin
       select @errorcode = -1, @errormsg = '��ˮ����ʧ��'
       goto exit_end
     end 
--3.2 ��Ӧ���ֵ����
	insert into wsupplier
    select @p_sid,@p_sname,@p_addr,@p_stel,@p_spre	
    if ( @@error <> 0 )
      begin
       select @errorcode = -1, @errormsg = '��Ӧ�̱����ʧ��'
       goto exit_end
	  end  
---��Ϊ�д��󶼵�goto���˻ع���û������ύ����
  select errorcode = 0 , errormsg = '��Ӧ����ӳɹ�'
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

execute sys_supplieradd '00000001','��������1','3792','����·199��','13237179998','����2' 

------------------------------------------
--�޸�
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
--��������
declare @remark varchar(100)  
declare @p_date date
select @p_date=wdate from wstatus  
--����ȡֵ
select @remark=@p_sid+'��'+@p_addr+'��'+@p_stel+'��'+@p_spre

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
 --1���ж�״̬�Ƿ�Ϊ0 
 declare @status varchar(2)
 select @status=status from wstatus
if @status <>0
 begin
   select @errorcode = -1, @errormsg = '״̬�쳣��Ϊ0�����ɽ��в���'
   goto exit_end
  end
--1.���¼�빩Ӧ��id�����ڣ��򲻿��޸���Ҫ�����
if not exists (select sid from wsupplier where sid =@p_sid)
      begin
       select @errorcode = -1, @errormsg = '��Ʒ��ϸ���в����ڴ˹�Ӧ��'
       goto exit_end
	  end 

--2.�жϣ����¼������ڵĹ�Ӧ����Ϣһ��
if @p_sname is not null and @sname<>@p_sname
     begin
       select @errorcode = -1, @errormsg = '��Ʒ��ϸ���в����ڴ˹�Ӧ��'
       goto exit_end
	  end 
if @p_addr is not null and @addr<>@p_addr
     begin
       select @errorcode = -1, @errormsg = '��Ʒ��ϸ���в����ڴ˹�Ӧ��'
       goto exit_end
	  end 
if @p_sname is not null and @sname<>@p_sname
     begin
       select @errorcode = -1, @errormsg = '��Ʒ��ϸ���в����ڴ˹�Ӧ��'
       goto exit_end
	  end 
if @p_sname is not null and @sname<>@p_sname
     begin
       select @errorcode = -1, @errormsg = '��Ʒ��ϸ���в����ڴ˹�Ӧ��'
       goto exit_end
	  end 

--2.��ʼ����
begin tran  --������begin tran
	select @starttran = '1'
--2.1:������ˮ
	insert into statement select '0302' as bid ,@p_date as wdate,@p_hid as hid, '' as iid2, '' as iname ,0 as iprice ,'' as iunit,0 as iamount,0 as imoney,
	@sname as sname ,'' as cname ,'' as pid ,'' as cuid,@remark as sinfo,'' as place,getdate() as oprdate
	if ( @@error <> 0 )
      begin
       select @errorcode = -1, @errormsg = '��ˮ����ʧ��'
       goto exit_end
	  end 

--2.2�����¹�Ӧ����ϸ��
if (@sname is not null)
	update wsupplier set  sname=@sname where  sid=@p_sid 
if (@addr is not null)
	update wsupplier set  saddr=@addr where  sid=@p_sid 
if (@stel is not null)
	update wsupplier set  stel=@stel where  sid=@p_sid 
if (@spre is not null)
	update wsupplier set  spre=@spre where  sid=@p_sid 
---��Ϊ�д��󶼵�goto���˻ع���û������ύ����
  select errorcode = 0 , errormsg = '��Ӧ���޸ĳɹ�'
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
--ɾ��
use YStore
go
if exists (select * from sysobjects where name = 'sys_suppliercut')
  drop proc sys_suppliercut
go
create procedure sys_suppliercut 
 @p_hid varchar(8) ,--������id
 @p_sid varchar(8)--��Ʒid
 as
 begin
--��������
declare  @sname  varchar(100)   
 declare @p_date date
select @p_date=wdate from wstatus  

--��ֵ���б仯�ģ�

select @sname=sname from wsupplier where sid=@p_sid
--�������̶�ֵ
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
   --1���ж�״̬�Ƿ�Ϊ0 
 declare @status varchar(2)
 select @status=status from wstatus
if @status <>0
 begin
   select @errorcode = -1, @errormsg = '״̬�쳣��Ϊ0,��Ӧ��ɾ��ʧ��'
   goto exit_end
  end
--1.�жϣ�����ù�Ӧ�̲����ڣ�������ɾ��
if not exists (select sname from wsupplier where sid=@p_sid)
begin
   select @errorcode = -1, @errormsg = '�ù�Ӧ�̲�����'
    goto exit_end
  end

--2.��ʼ����
begin tran
   select @starttran = '1'
--2.1��������ˮ
insert into statement select '0303' as bid ,@p_date as wdate,@p_hid as hid, '' as iid2, ''as iname ,0 as iprice ,'' as iunit,0 as iamount,0 as imoney,
@sname as sname ,'' as cname ,'' as pid ,'' as cuid,'' as sinfo,'' as place,getdate() as oprdate
 if ( @@error <> 0 )
     begin
       select @errorcode = -1, @errormsg = '��ˮ����ʧ��'
       goto exit_end
     end		
--2.1:��Ӧ�̽��и���	
delete from wsupplier where sid=@p_sid
 if ( @@error <> 0 )
     begin
       select @errorcode = -1, @errormsg = '��Ӧ��ɾ��ʧ��'
       goto exit_end
     end				
	
---��Ϊ�д��󶼵�goto���˻ع���û������ύ����
  select errorcode = 0 , errormsg = '��Ӧ��ɾ���ɹ�'
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