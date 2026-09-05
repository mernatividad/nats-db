alter table thebudolfinds.users add column role text not null default 'user';
alter table thebudolfinds.users add constraint users_role_check check (role in ('user', 'moderator', 'admin'));
grant all on thebudolfinds.users to service_role;
