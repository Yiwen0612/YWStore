-- =============================================
-- Author:		<Yiwen Wu>
-- Create date: <2019-07-06>
-- Description:	<���д洢����>
-- =============================================
use YStore
go
if exists (select * from sysobjects where name = 'sys_begin')
  drop proc sys_begin
go
create procedure sys_begin 
@p_hid varchar(8),--������id
-------------
@p_date date --�л�����

as 
  declare @errorcode int, @errormsg varchar(255), @starttran char
  select @errorcode = 0, @errormsg = '', @starttran = '0'
   
  declare @wdate1 date,@status1 varchar(2)
  select @wdate1=wdate, @status1=status from wstatus 
  
------
declare @right int

declare @p_erromsg varchar(100) 
execute @right= inside_get_handler @p_hid,@p_erromsg  output
if @right=-1
 begin
   select @errorcode = -1, @errormsg = @p_erromsg
   goto exit_end
  end
  
--1 ϵͳ״̬���ж�

  if ( @status1 <> '2' )
  begin
   select @errorcode = -1, @errormsg = '״̬�쳣,��ǰ״̬Ϊ'+convert(varchar(2),@status1)
    goto exit_end
  end
 --2 ϵͳ���ڵ��ж�
   if ( @wdate1 >@p_date )  
  begin
  select @errorcode = -1, @errormsg = 'ϵͳ����Ϊ'+convert(varchar(10),@wdate1)+'����ָ������'+convert(varchar(10),@p_date)
    goto exit_end
  end
  if ( @wdate1 =@p_date ) 
  begin
  select @errorcode = -1, @errormsg = '���ղ����ظ��л���ϵͳ����Ϊ'+convert(varchar(10),@p_date)
    goto exit_end
  end
--3 ������
    begin tran
   select @starttran = '1'
 -- 3.1  �鵵����
   --3.1.1����ʷ��������ɾ��Ҫ�鵵�Ķ������ٹ鵵
   -- if  (select count( * )from statement where wdate=@p_date)>0 
	delete from hstatement where wdate=@p_date
	insert into hstatement select bid,wdate,hid,iid2,iname,price,iunit,iamount,imoney,sname,cname,pid,cuid,remark,place,oprdate from statement
	delete from statement 
    if ( @@error <> 0 )
     begin
      select @errorcode = -1, @errormsg = '�鵵ʧ��'
      goto exit_end
     end 
	  --3.1.2��ˮ��identity��λ	
	DBCC CHECKIDENT(statement, RESEED, 1)
--3.2 �ʽ���
--3.2.1�ʽ����
	delete wbank where wdate  >=@p_date
	 insert into wbank
	  (wdate,cuid,pid,yrbalance,trbalance)
	 values
	 (@p_date,'0','0','0.00','0.00'),
	 (@p_date,'1','0','0.00','0.00'),
	 (@p_date,'2','0','0.00','0.00')
	  
      if ( @@error <> 0 )
      begin
      select @errorcode = -1, @errormsg = '�ʽ����ʧ��'
      goto exit_end
	  end
  
  ---3.2.2�ʽ�����
  begin
	  declare @trbalance0 float,@cuid varchar(2),@lastdate1 date
	  select @cuid=0
	  select @lastdate1=wdate from wstatus
	  select @trbalance0 =  trbalance from wbank where wdate=@wdate1 and cuid=@cuid
	  --select * from wbank where wdate=@lastdate1 and cuid=@cuid
	 -- select @trbalance0,@lastdate1

	  update wbank
	  set yrbalance=@trbalance0,trbalance=@trbalance0
	  from wbank 
	  where wdate=@p_date and cuid=@cuid
  end
 if ( @@error <> 0 )
      begin
      select @errorcode = -1, @errormsg = '�ʽ����ʧ��'
      goto exit_end
	  end
 --3.3��������
update wstorage set lastnum=num
 if ( @@error <> 0 )
      begin
      select @errorcode = -1, @errormsg = '������ʧ��'
      goto exit_end
	  end
 --3.4ϵͳ״̬�� ����  
update wstatus set status='0',wdate=@p_date,lastdate=@wdate1 --where 1=2

 if ( @@rowcount <> 1 )
      begin
      select @errorcode = -1, @errormsg = '״̬�����ʧ��'
      goto exit_end
	  end
---��Ϊ�д��󶼵�goto���˻ع���û������ύ����
  select errorcode = 0 , errormsg = '���гɹ���ϵͳ����Ϊ'+convert(varchar(10),@p_date)
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

--execute sys_begin '2019-08-10','00001'
