-- =============================================
-- Author:		<Yiwen Wu>
-- Create date: <2019-07-06>
-- Description:	<��Ʒ���۴���洢����>
-- =============================================
use YStore
go
if exists (select * from sysobjects where name = 'sys_sell')
  drop proc sys_sell
go
create procedure sys_sell
@p_hid varchar(8)  ,--������id
@p_iid2 varchar(8),--��Ʒid
@p_iprice float,--��Ʒ�����۸�
@p_iamount  int ,--��Ʒ��������
@p_cid varchar(100) ,--�ͻ�id
@p_place varchar(2),--���λ��
@p_pid  varchar(2),   --֧����ʽ
@p_cuid varchar(4)--��������
as
declare @iname  varchar(30) ,@iunit  varchar(10),@imoney float  
declare @cname  varchar(100) ,@lastnum int     

--����ȡֵ
select @iname=iname from witem where iid2=@p_iid2
select @iunit =iunit from witem where iid2=@p_iid2
select @imoney = @p_iamount * @p_iprice 
select @cname=cname from wclient where cid=@p_cid
select @lastnum=num from wstorage where iid2=@p_iid2
--�������̶�ֵ
 declare @p_date date
 select @p_date=wdate from wstatus  --���幺������
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
 --1���ж�״̬�Ƿ�Ϊ0 
 declare @status varchar(2)
 select @status=status from wstatus
if @status <>0
 begin
   select @errorcode = -1, @errormsg = '״̬�쳣��Ϊ0�����ɽ��в���'
   goto exit_end
  end
--1.������Ʒ������Ʒ������
if not exists (select * from wstorage where iid2=@p_iid2 and place=@p_place)
begin
   select @errorcode = -1, @errormsg = '�޴���Ʒ'
    goto exit_end
  end
--2.��治�㲻������
if (@p_iamount>@p_num) 
begin
   select @errorcode = -1, @errormsg = '�õ�������������'
    goto exit_end
  end
--3.��ʼ����
begin tran  --������begin tran
   select @starttran = '1'
--3.1��������ˮ

---1.��ˮ����
  insert into statement select '0102' as bid ,@p_date as wdate,@p_hid as hid, @p_iid2 as iid2, @iname as iname ,@p_iprice as iprice ,@iunit as iunit,@p_iamount as iamount,@imoney as imoney,
  '' as sname ,@cname as cname ,@p_pid as pid ,@p_cuid as cuid,@p_cid as sid,@p_place as place,getdate() as oprdate
  if ( @@error <> 0 )
     begin
       select @errorcode = -1, @errormsg = '��ˮ����ʧ��'
       goto exit_end
     end 

--2.������	
		update wstorage
		set num=num-@p_iamount,cost=cost-@imoney
		where iid2=@p_iid2 and place=@p_place
		
        if ( @@error <> 0 )
          begin
           select @errorcode = -1, @errormsg = '������Ʒ����ʧ��'
           goto exit_end
	      end 
	  
--3.�ʽ�ı仯
update wbank
set trbalance = trbalance+@imoney
where wdate = convert (date, @p_date,23) and cuid=@p_cuid 
if ( @@error <> 0 )
      begin
       select @errorcode = -1, @errormsg = '�ʽ����ʧ��'
       goto exit_end
	  end  
---��Ϊ�д��󶼵�goto���˻ع���û������ύ����
  select errorcode = 0 , errormsg = '���۳ɹ�'
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