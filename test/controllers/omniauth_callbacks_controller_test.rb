require "application_controller_test_case"

class OmniauthCallbacksControllerTest < ApplicationControllerTestCase
  setup do
    @oauth_user = create_user(email: 'user1@gmail.com', password: 'secret', provider: 'google_oauth2', uid: '123456789')
    OmniAuth.config.test_mode = true
  end

  test "google_oauth2 of a user that exists should redirect to root_path" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: '123456789',
      info: {
        email: @oauth_user.email
      }
    )

    post user_google_oauth2_omniauth_callback_path
    assert_redirected_to root_path
  end

  test "google_oauth2 of a user that exists should update the user" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: '555555555',
      info: {
        email: @oauth_user.email
      }
    )

    assert_no_difference "User.count" do
      post user_google_oauth2_omniauth_callback_path
    end

    assert_equal "555555555", @oauth_user.reload.uid
  end

  test "google_oauth2 of a user that doesn't exist should create a new user" do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: "345678901",
      info: {
        email: 'new@gmail.com'
      }
    )

    assert_difference "User.count", 1 do
      post user_google_oauth2_omniauth_callback_path
    end
  end

  test 'create a user with google with approvals in session should create user with approvals' do
    subject1 = create_subject(name: "Subject 1", credits: 16, exam: false)
    subject2 = create_subject(name: "Subject 2", credits: 16, exam: true)
    patch approve_subject_path(subject1), params: {
      subject: {
        course_approved: 'yes'
      },
      format: 'turbo_stream'
    }
    patch approve_subject_path(subject2), params: {
      subject: {
        exam_approved: 'yes'
      },
      format: 'turbo_stream'
    }

    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: "345678901",
      info: {
        email: 'new@gmail.com'
      }
    )

    post user_google_oauth2_omniauth_callback_path

    user = User.where(email: 'new@gmail.com').first
    assert_equal [subject1.course.id, subject2.exam.id], user.approvals[:approved_approvable_ids]
  end
end
