-- =============================================
-- Author:		<Yiwen Wu>
-- Create date: <2019-07-06>
-- Description:	<�ɹ����۴���洢����>
-- =============================================
use YStore
go
if exists (select * from sysobjects where name = 'sys_buy')
  drop proc sys_buy
go
create procedure sys_buy 
@p_hid varchar(8) ,--������id
------------
@p_iid2 varchar(8),--��Ʒid
@p_iprice float,--��Ʒ�ۼ�
@p_iamount  int,--��Ʒ��������
@p_sid varchar(100),--��Ӧ��id
@p_place varchar(2),--���λ��
@p_pid  varchar(2),  --֧����ʽ
@p_cuid varchar(4)--��������
  
as
begin

--����ȡֵ
declare @iname  varchar(30) ,@iunit  varchar(10),@imoney float, @sname  varchar(100)
SELECT @iname=iname from witem where iid2=@p_iid2
select @iunit =iunit from witem where iid2=@p_iid2
select @imoney = @p_iamount * @p_iprice 
select @sname=sname from wsupplier where sid=@p_sid

 declare @p_date date
 select @p_date=wdate from wstatus  --���幺������
 declare @p_trbalance float
 select @p_trbalance=trbalance from wbank where wdate=@p_date and cuid=@p_cuid

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
--1.�ʽ��ж�
if (@imoney>@p_trbalance)
 begin
   select @errorcode = -1, @errormsg = '�ʽ𲻹������ɲɹ�'
    goto exit_end
  end
--2.��Ʒ�����ж�
if not exists(select iid2 from witem where iid2=@p_iid2)
 begin
   select @errorcode = -1, @errormsg = '��������Ʒ�����в������Ʒ�ٽ��вɹ�'
    goto exit_end
  end

--2.������
begin tran
   select @starttran = '1'
--3.1 ������ˮ
  insert into statement select '0101' as bid ,@p_date as wdate,@p_hid as hid, @p_iid2 as iid2,
	@iname as iname ,@p_iprice as iprice ,@iunit as iunit,@p_iamount as iamount,@imoney as imoney,@sname as sname ,
	'' as cname ,@p_pid as pid ,@p_cuid as cuid,@p_sid as sid,@p_place as place,getdate() as oprdate
	  if ( @@error <> 0 )
     begin
       select @errorcode = -1, @errormsg = '��ˮ����ʧ��'
       goto exit_end
     end 
--3.2:���¿��
--3.2.1������жϣ�������д���Ʒ�������� 
  if exists (select * from wstorage where iid2=@p_iid2 and place=@p_place)
   begin
     update wstorage
     set num=num+@p_iamount,cost=cost+@imoney
     where iid2=@p_iid2 and place=@p_place
	 if ( @@error <> 0 )
      begin
       select @errorcode = -1, @errormsg = '������Ʒ����ʧ��'
       goto exit_end
	  end  
   end
--3.2.1������жϣ������û�д���Ʒ����һ�β���
  else
   begin
    insert into wstorage
    select  @p_iid2 as iid2,@iname as iname,@iunit as iunit,@p_iamount as num,@imoney as cost, @p_place as place,0 as lastnum
	if ( @@error <> 0 )
      begin
       select @errorcode = -1, @errormsg = '��Ʒ������ʧ��'
       goto exit_end
	  end  
   end
--3.3���ʽ�����
  update wbank
  set trbalance = trbalance-@imoney
  where wdate = convert (date, @p_date,23) and cuid=@p_cuid 
 if ( @@error <> 0 )
      begin
       select @errorcode = -1, @errormsg = '�ʽ����ʧ��'
       goto exit_end
	  end  
---��Ϊ�д��󶼵�goto���˻ع���û������ύ����
  select errorcode = 0 , errormsg = '�ɹ��ɹ�'
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
--sp_help sys_buy
--select * from wstorage
--select * from wbank where wdate=(select wdate from wstatus)
--select * from statement
  --alter table wstorage drop column lastnum
  --select * from wstatus
 --execute sys_buy  '00000002','0207',3,300,'0101','1', '2', '0'