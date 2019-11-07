require "csv"

namespace :user_list do
  desc "CSV of company users"
  task company_users: :environment do
    columns = [
      :email,
      :company,
      :is_admin,
    ]

    header_row = {
      email: "Email",
      company: "Company",
      is_admin: "Admin?",
    }

    csv_string = CSV.generate(col_sep: ";", headers: header_row.values_at(*columns), write_headers: true) do |csv|
      User.where(is_customer: false).each do |user|
        row = {
          email: user.email,
          company: user.company.try(:name),
          is_admin: user.is_admin? ? "yes" : "no",
        }

        csv << row.values_at(*columns)
      end
    end

    puts "=" * 80
    puts
    puts csv_string
    puts
    puts "=" * 80
  end

  desc "CSV of customer users"
  task customer_users: :environment do
    columns = [
      :email,
      :cf_company,
      :customer,
    ]

    header_row = {
      email: "Email",
      cf_company: "CF parent company",
      customer: "User company",
    }

    csv_string = CSV.generate(col_sep: ";", headers: header_row.values_at(*columns), write_headers: true) do |csv|
      UserCustomerAccess.active.includes(:user, :company, :customer).each do |user_customer_access|
        row = {
          email: user_customer_access.user.email,
          cf_company: user_customer_access.company.name,
          customer: user_customer_access.customer.name,
        }

        csv << row.values_at(*columns)
      end
    end

    puts "=" * 80
    puts
    puts csv_string
    puts
    puts "=" * 80
  end
end
