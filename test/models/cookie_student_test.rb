require 'test_helper'

class CookieStudentTest < ActiveSupport::TestCase
  test "#add adds approvable.id only if available" do
    subject1 = create :subject, :with_exam
    subject2 = create :subject, :with_exam

    create(:subject_prerequisite, approvable: subject2.course, approvable_needed: subject1.course)

    cookies = {}
    student = CookieStudent.new(cookies)

    student.add(subject2.course)

    assert_nil cookies[:approved_approvable_ids]

    student.add(subject1.course)
    assert_equal [subject1.course.id].to_json, cookies[:approved_approvable_ids]

    student.add(subject2.course)
    assert_equal [subject1.course.id, subject2.course.id].to_json, cookies[:approved_approvable_ids]
  end

  test "#remove removes approvable.id and other approvables that are not available anymore" do
    subject1 = create :subject, :with_exam
    subject2 = create :subject, :with_exam
    subject3 = create :subject, :with_exam
    subject4 = create :subject, :with_exam

    create(:subject_prerequisite, approvable: subject2.course, approvable_needed: subject3.course)
    create(:subject_prerequisite, approvable: subject3.course, approvable_needed: subject1.course)

    cookies = {
      approved_approvable_ids: [subject1.course.id, subject2.course.id, subject3.course.id,
                                subject4.course.id].to_json
    }
    student = CookieStudent.new(cookies)

    student.remove(subject1.course)

    assert_equal [subject4.course.id].to_json, cookies[:approved_approvable_ids]
  end

  test "#available? returns true if subject_or_approvable is available" do
    subject1 = create :subject, :with_exam
    create(:subject_prerequisite, approvable: subject1.exam, approvable_needed: subject1.course)

    assert CookieStudent.new({ approved_approvable_ids: "[]" }).available?(subject1)
    assert CookieStudent.new({ approved_approvable_ids: "[]" }).available?(subject1.course)
    assert_not CookieStudent.new({ approved_approvable_ids: "[]" }).available?(subject1.exam)
    assert CookieStudent.new({
                               approved_approvable_ids: [subject1.course.id].to_json
                             }).available?(subject1.exam)
  end

  test "#approved? returns true if subject_or_approvable is approved" do
    subject1 = create :subject
    subject2 = create :subject, :with_exam

    assert_not CookieStudent.new({ approved_approvable_ids: "[]" }).approved?(subject1)
    assert_not CookieStudent.new({ approved_approvable_ids: "[]" }).approved?(subject1.course)
    assert CookieStudent.new({ approved_approvable_ids: [subject1.course.id].to_json }).approved?(subject1)
    assert CookieStudent.new({
                               approved_approvable_ids: [subject1.course.id].to_json
                             }).approved?(subject1.course)

    assert_not CookieStudent.new({ approved_approvable_ids: "[]" }).approved?(subject2)
    assert_not CookieStudent.new({ approved_approvable_ids: "[]" }).approved?(subject2.course)
    assert_not CookieStudent.new({ approved_approvable_ids: "[]" }).approved?(subject2.exam)
    assert_not CookieStudent.new({ approved_approvable_ids: [subject2.course.id].to_json }).approved?(subject2)

    assert CookieStudent.new({ approved_approvable_ids: [subject2.exam.id].to_json }).approved?(subject2)
    assert_not CookieStudent.new({
                                   approved_approvable_ids: [subject2.exam.id].to_json
                                 }).approved?(subject2.course)
    assert CookieStudent.new({ approved_approvable_ids: [subject2.exam.id].to_json }).approved?(subject2.exam)
  end

  test "#group_credits returns approved credits for the given group" do
    group1 = create :subject_group
    group2 = create :subject_group

    subject1 = create :subject, credits: 10, group: group1
    subject2 = create :subject, :with_exam, credits: 11, group: group1
    subject3 = create :subject, credits: 12, group: group2

    student = CookieStudent.new(approved_approvable_ids: "[]")
    assert_equal 0, student.group_credits(group1)
    student = CookieStudent.new(approved_approvable_ids: [subject1.course.id].to_json)
    assert_equal 10, student.group_credits(group1)
    student = CookieStudent.new(approved_approvable_ids: [subject1.course.id, subject2.course.id].to_json)
    assert_equal 10, student.group_credits(group1)
    student = CookieStudent.new(approved_approvable_ids: [subject1.course.id, subject2.exam.id].to_json)
    assert_equal 21, student.group_credits(group1)
    student = CookieStudent.new(approved_approvable_ids: [subject1.course.id, subject2.exam.id,
                                                          subject3.course.id].to_json)
    assert_equal 21, student.group_credits(group1)
  end

  test "#total_credits returns total approved credits" do
    group1 = create :subject_group
    group2 = create :subject_group

    subject1 = create :subject, credits: 10, group: group1
    subject2 = create :subject, :with_exam, credits: 11, group: group1
    subject3 = create :subject, credits: 12, group: group2

    student = CookieStudent.new(approved_approvable_ids: "[]")
    assert_equal 0, student.total_credits
    student = CookieStudent.new(approved_approvable_ids: [subject1.course.id].to_json)
    assert_equal 10, student.total_credits
    student = CookieStudent.new(approved_approvable_ids: [subject1.course.id, subject2.course.id].to_json)
    assert_equal 10, student.total_credits
    student = CookieStudent.new(approved_approvable_ids: [subject1.course.id, subject2.exam.id].to_json)
    assert_equal 21, student.total_credits
    student = CookieStudent.new(approved_approvable_ids: [subject1.course.id, subject2.exam.id,
                                                          subject3.course.id].to_json)
    assert_equal 33, student.total_credits
  end

  test "#add subject.exam adds subject.course as well" do
    subject = create :subject, :with_exam
    cookies = { approved_approvable_ids: "[]" }
    student = CookieStudent.new(cookies)
    student.add(subject.exam)

    assert_equal [subject.exam.id, subject.course.id].to_json, cookies[:approved_approvable_ids]
  end
end
