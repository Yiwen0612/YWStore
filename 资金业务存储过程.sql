use YStore
go
if exists (select * from sysobjects where name = 'sys_bank')
  drop proc sys_bank
go
create procedure sys_bank
@p_hid varchar(100),--������
@p_imoney float, --���׽��
@p_pid varchar(2),--֧����ʽ
@p_cuid varchar(4)  --����
as
--��������
declare @iid2 varchar(8),@iprice float   ,@iamount  int  ,@remark varchar(100) ,@place varchar(2)
declare @iname varchar(30) ,@iunit  varchar(10),@sname  varchar(100)  
declare @bid varchar(4),@cname  varchar(100)
declare @p_date date
select @p_date=wdate from wstatus
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
-------
if @p_imoney >0
select @bid='0001'
else if @p_imoney <0
begin
select @bid='0002'
  declare @p_trbalance float
  select @p_trbalance =trbalance from wbank where wdate=@p_date and cuid=@p_cuid
--1.�жϣ������ǰת���ʽ���������ʽ�
if abs(@p_imoney)>@p_trbalance
 begin
   select @errorcode = -1, @errormsg = '��ǰת���ʽ���������ʽ�'
   goto exit_end
 end
 end

 --��ֵ���б仯�ģ�

--�������̶�ֵ


   --1���ж�״̬�Ƿ�Ϊ0 
 declare @status varchar(2)
 select @status=status from wstatus
if @status <>0
 begin
   select @errorcode = -1, @errormsg = '״̬�쳣��Ϊ0�����ɽ��в���'
   goto exit_end
  end

--1.��ʼ����
begin tran  --������begin tran
   select @starttran = '1'
--1.1:��ˮ���

insert into statement select @bid as bid ,@p_date as wdate,@p_hid as hid, ''as iid2, '' as iname ,0 as iprice ,''as iunit,0 as iamount,abs(@p_imoney) as imoney,'' as sname ,'' as cname ,@p_pid as pid ,@p_cuid as cuid,'' as remark,'' as place,getdate() as oprdate
if ( @@error <> 0 )
    begin
       select @errorcode = -1, @errormsg = '��ˮ�����ʧ��'
       goto exit_end
	  end  
--1.2���ʽ���
update wbank
set trbalance = trbalance+@p_imoney
where wdate = convert (varchar(100), @p_date,23) and cuid=@p_cuid 
if ( @@error <> 0 )
    begin
       select @errorcode = -1, @errormsg = '�ʽ�����ʧ��'
       goto exit_end
	  end 		
	

---��Ϊ�д��󶼵�goto���˻ع���û������ύ����
if @bid='0001'
  select errorcode = 0 , errormsg = '�ʽ�ת��ɹ�'
  else if @bid='0002'
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

go


--execute sys_bank '00000002',-1,'0','0'
--select * from statement
--select * from wbank where wdate=(select wdate from wstatus)

