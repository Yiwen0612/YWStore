--����Ա��������
use YStore
go
if exists (select * from sysobjects where name='inside_get_handler')
drop proc inside_get_handler
go
create procedure inside_get_handler
@p_hid varchar(8),
@p_erromsg varchar(100) output

as



if not exists (select hid from whandler where hid=@p_hid)
begin
select @p_erromsg='�����˲�����'

return -1
end
else
begin
select @p_erromsg='��ȡ�ɹ�'

return 0
end

go

--execute inside_get_handler '001',''