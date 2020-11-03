--�ʽ�ת��
use YStore
go
if exists (select * from sysobjects where name = 'sys_convertout')
  drop proc sys_convertout
go
create procedure sys_convertout
@hid varchar(100),
@imoney float, @pid varchar(2),@cuid varchar(4)  
as
begin
declare @p_date date
select @p_date=wdate from wstatus
 declare @errorcode int, @errormsg varchar(255), @starttran char
  select @errorcode = 0, @errormsg = '', @starttran = '0'
   --1���ж�״̬�Ƿ�Ϊ0 
 declare @status varchar(2)
 select @status=status from wstatus
if @status <>0
 begin
   select @errorcode = -1, @errormsg = '״̬�쳣��Ϊ0�����ɽ��в���'
   goto exit_end
  end

  declare @p_trbalance float
  select @p_trbalance =trbalance from wbank where wdate=@p_date and cuid=@cuid
--1.�жϣ������ǰת���ʽ���������ʽ�
if @imoney>@p_trbalance
 begin
   select @errorcode = -1, @errormsg = '��ǰת���ʽ���������ʽ�'
   goto exit_end
 end
--2.��ʼ����

begin tran  --������begin tran
   select @starttran = '1'
--2.1:��ˮ����
insert into statement select '0002'as bid ,@p_date as wdate,@hid as hid, ''as iid2, '' as iname ,0 as iprice ,'' as iunit,0 as iamount,@imoney as imoney,'' as sname ,'' as cname ,@pid as pid ,@cuid as cuid,''as remark,'' as place,getdate() as oprdate
	if ( @@error <> 0 )
    begin
       select @errorcode = -1, @errormsg = '��ˮ����ʧ��'
       goto exit_end
	end 
--2.2���ʽ����
update wbank
set trbalance = trbalance-@imoney
where wdate = convert (varchar(100), @p_date,23) and cuid=@cuid 
if ( @@error <> 0 )
    begin
       select @errorcode = -1, @errormsg = '�ʽ�����ʧ��'
       goto exit_end
	  end  
---��Ϊ�д��󶼵�goto���˻ع���û������ύ����
  select errorcode = 0 , errormsg = '�ʽ�ת���ɹ�'
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

--execute sys_convertout '000001',1,'0','0'