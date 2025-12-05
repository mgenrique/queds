#!/usr/bin/env python3
"""
Idempotent seeder for development/production environments.
Creates a demo user and example accounts if they don't exist.
Safe to run multiple times.
"""
import os
from config import settings
from models.sql import create_db_connection, db_session


def ensure_connection():
    # Initialize DB connection for this process
    create_db_connection(settings.SQL_CONF)


def create_demo_user(email='demo@queds.com', password='supersecret'):
    from models.system import User
    # Try to find by email
    user = User.get_by_email(email)
    if user:
        print(f"Demo user already exists: {email} (id={user.id})")
        return user

    print(f"Creating demo user: {email}")
    u = User(email=email, password=password)
    try:
        db_session.add(u)
        db_session.commit()
    except Exception:
        db_session.rollback()
        # attempt to re-query
        u = User.get_by_email(email)
        if u:
            return u
        raise
    return u


def ensure_account(user, entity_name, account_name, currency='EUR', allows_csv=False):
    from models.system import Entity, Account
    # Find entity by name
    entity = Entity.query.filter(Entity.name == entity_name).first()
    if not entity:
        print(f"Entity '{entity_name}' not found, skipping account creation")
        return None

    # Check if account already exists for this user with the same name
    existing = Account.query.filter(Account.user_id == user.id, Account.name == account_name).first()
    if existing:
        print(f"Account already exists: {account_name} (id={existing.id})")
        return existing

    print(f"Creating account '{account_name}' for user {user.email} -> entity {entity_name}")
    account = Account(
        name=account_name,
        entity_id=entity.id,
        user_id=user.id,
        currency=currency,
        balance=0,
        virtual_balance=0,
        allows_csv=allows_csv
    )
    try:
        account.save()
    except Exception as e:
        print(f"Error creating account: {e}")
        return Account.query.filter(Account.user_id == user.id, Account.name == account_name).first()
    return account


def main():
    ensure_connection()
    user = create_demo_user()
    # Create sample accounts
    ensure_account(user, 'Degiro', 'Demo Degiro', currency='EUR', allows_csv=False)
    ensure_account(user, 'Bitstamp', 'Demo Bitstamp', currency='EUR', allows_csv=True)

    print("Seeding complete.")


if __name__ == '__main__':
    main()
