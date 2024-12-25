package com.spelist.tunekey.ui.teacher.students.activity;

import android.accounts.Account;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.Scope;
import com.google.android.gms.tasks.Task;

import com.google.api.client.extensions.android.http.AndroidHttp;
import com.google.api.client.googleapis.extensions.android.gms.auth.GoogleAccountCredential;
import com.google.api.client.googleapis.extensions.android.gms.auth.UserRecoverableAuthIOException;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.people.v1.PeopleService;
import com.google.api.services.people.v1.model.ListConnectionsResponse;
import com.google.api.services.people.v1.model.Person;
import com.orhanobut.logger.Logger;
import com.spelist.tools.custom.AddressBookEntity;
import com.spelist.tools.tools.SLJsonUtils;
import com.spelist.tunekey.BR;
import com.spelist.tunekey.R;
import com.spelist.tunekey.customView.SLToast;
import com.spelist.tunekey.databinding.ActivityAddressBookBinding;
import com.spelist.tunekey.entity.GooglePeopleEntity;
import com.spelist.tunekey.entity.MaterialEntity;
import com.spelist.tunekey.ui.teacher.students.vm.AddressBookViewModel;

import java.io.IOException;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import me.goldze.mvvmhabit.base.BaseActivity;
import me.tatarka.bindingcollectionadapter2.BindingRecyclerViewAdapter;

public class AddressBookActivity extends BaseActivity<ActivityAddressBookBinding, AddressBookViewModel> {
    private GoogleSignInClient mGoogleSignInClient;
    private Account mAccount;
    private String messageString = "";
    private static final int RC_SIGN_IN = 9001;
    private static final String CONTACTS_SCOPE = "https://www.googleapis.com/auth/contacts.readonly";
    // Global instance of the JSON factory
    // Bundle key for account object

    // Request codes
    private static final int RC_RECOVERABLE = 9002;

    // Global instance of the HTTP transport
    private static final HttpTransport HTTP_TRANSPORT = AndroidHttp.newCompatibleTransport();
    boolean isHaveDefaultData = false;

    @Override
    public int initContentView(Bundle savedInstanceState) {
        return R.layout.activity_address_book;
    }

    @Override
    public int initVariableId() {
        return BR.viewModel;
    }


    @Override
    public void initData() {
        super.initData();
        Intent intent = getIntent();
        if (intent.getStringExtra("toAddressBook") != null) {
            viewModel.typeFromContactTypes = AddressBookViewModel.ContactTypes.addressBook;
            viewModel.pageAction = AddressBookViewModel.PageAction.addStudentFromAddressBook;
            viewModel.initToolbar();
            binding.nextBtn.setEnabled(false);
        }
        if (intent.getStringExtra("googleContact") != null) {
            viewModel.typeFromContactTypes = AddressBookViewModel.ContactTypes.googleContact;
            viewModel.pageAction = AddressBookViewModel.PageAction.addStudentFromAddressBook;
            viewModel.initToolbar();
            binding.nextBtn.setEnabled(false);
        }
        if (intent.getStringExtra("sendMessage") != null) {
            messageString = intent.getStringExtra("sendMessage");
            viewModel.typeFromContactTypes = AddressBookViewModel.ContactTypes.phoneContact;
            viewModel.pageAction = AddressBookViewModel.PageAction.sendMessage;
            viewModel.initToolbar();
            binding.nextBtn.setEnabled(false);
        }

        binding.setAdapter(new BindingRecyclerViewAdapter());
        LinearLayoutManager ms = new LinearLayoutManager(this);
        ms.setOrientation(LinearLayoutManager.HORIZONTAL);
        binding.rvHeading.setLayoutManager(ms);
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this);
        linearLayoutManager.setOrientation(LinearLayoutManager.VERTICAL);
        binding.rvStudent.setLayoutManager(linearLayoutManager);
        binding.rvStudent.setItemAnimator(null);
//        Bundle toShareMaterial = intent.getBundleExtra("toShareMaterial");
//        if (toShareMaterial != null) {
//            binding.rvHeading.setVisibility(View.VISIBLE);
//            binding.rvStudent.setVisibility(View.VISIBLE);
//            binding.bottomBtnContainer.setVisibility(View.GONE);
//            binding.nextBtn.setButtonText("SHARE");
//            viewModel.selectedMaterialIds = toShareMaterial.getStringArrayList("selectedMaterialIds");
//            viewModel.typeFromContactTypes = AddressBookViewModel.ContactTypes.appContact;
//            viewModel.pageAction = AddressBookViewModel.PageAction.shareMaterial;
//            viewModel.initToolbar();
//        }
        if (intent.getSerializableExtra("shareMaterials") != null) {
            binding.rvHeading.setVisibility(View.VISIBLE);
            binding.rvStudent.setVisibility(View.VISIBLE);
            binding.nextBtn.setVisibility(View.GONE);
            binding.nextBtn.setText("SHARE");
            binding.buttonLayout.setVisibility(View.VISIBLE);
            binding.twoButtonLayout.setVisibility(View.VISIBLE);
            binding.btShareSilently.setVisibility(View.VISIBLE);
            binding.bottomRightButton.setEnabled(false);
            viewModel.isInFolder = intent.getBooleanExtra("isInFolder", false);
            viewModel.selectedMaterials = (List<MaterialEntity>) (ArrayList<MaterialEntity>) intent.getSerializableExtra("shareMaterials");
            for (MaterialEntity selectedMaterial : viewModel.selectedMaterials) {
                if (selectedMaterial.getStudentIds().size() > 0) {
                    isHaveDefaultData = true;
                }
            }
            viewModel.typeFromContactTypes = AddressBookViewModel.ContactTypes.appContact;
            boolean isStudio = intent.getBooleanExtra("isStudio", false);
            viewModel.pageAction = AddressBookViewModel.PageAction.shareMaterial;
            if (isStudio){
                viewModel.pageAction = AddressBookViewModel.PageAction.shareStudioMaterial;
            }
            viewModel.initToolbar();
            binding.btShareSilently.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    viewModel.shareMaterialToStudents();
                }
            });
        }
        viewModel.initData();
    }

    @Override
    public void initViewObservable() {
        viewModel.uc.shareMaterial.observe(this, aVoid -> {

        });
        viewModel.uc.toNewContact.observe(this, aVoid -> {
//            Intent intent = new Intent(AddressBookActivity.this, NewContactActivity.class);
//            intent.putExtra("data", (Serializable) viewModel.checkedDate);
//            startActivity(intent);
        });
        viewModel.clearSearchEdit.observe(this, aBoolean -> {

            binding.searchEdit.setText("");
        });
        viewModel.bottomButtonIsEnable.observe(this, isEnable -> {
            binding.nextBtn.setEnabled(isEnable);


            if (isHaveDefaultData) {
                if (isEnable) {
                    binding.bottomRightButton.setText("SHARE");
                } else {
                    binding.bottomRightButton.setText("DONE");
                }
                binding.bottomRightButton.setEnabled(true);
            } else {
                binding.bottomRightButton.setEnabled(isEnable);
            }
        });
        viewModel.getGoogleContact.observe(this, aBoolean -> {
            getGoogleContact();
        });
        viewModel.sendMessage.observe(this, addressBookEntities -> {
            finish();
            StringBuilder toNumbers = new StringBuilder();
            for (AddressBookEntity s : addressBookEntities) {
                if (!s.getPhone().equals("")) {
                    toNumbers.append(s.getPhone()).append(";");
                }
            }
            toNumbers = new StringBuilder(toNumbers.toString().substring(0, toNumbers.toString().length() - 1));
            String message = viewModel.studioName + messageString;

            Uri sendSmsTo = Uri.parse("smsto:" + toNumbers);
            Intent intent = new Intent(
                    Intent.ACTION_SENDTO, sendSmsTo);
            intent.putExtra("sms_body", message);
            startActivity(intent);
        });
    }

    @Override
    public void initView() {
        super.initView();
    }

    public void getGoogleContact() {
        GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestScopes(new Scope(CONTACTS_SCOPE))
                .requestServerAuthCode(getApplication().getBaseContext().getString(R.string.default_web_client_id))
                .requestEmail()
                .build();
        mGoogleSignInClient = GoogleSignIn.getClient(this, gso);

        Intent signInIntent = mGoogleSignInClient.getSignInIntent();
        startActivityForResult(signInIntent, RC_SIGN_IN);
        showDialog();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        // Result returned from launching the Intent from GoogleSignInApi.getSignInIntent(...);

        if (requestCode == RC_SIGN_IN) {
            Task<GoogleSignInAccount> task = GoogleSignIn.getSignedInAccountFromIntent(data);
            handleSignInResult(task);
            // Google Sign In was successful, authenticate with Firebase


        }
        if (requestCode == RC_RECOVERABLE) {
            if (resultCode == RESULT_OK) {
                getContacts();
            } else {
                dismissDialog();
                Toast.makeText(this, "Get contacts failed.", Toast.LENGTH_SHORT).show();
            }
        }
    }

    private void handleSignInResult(@NonNull Task<GoogleSignInAccount> completedTask) {

        try {
            GoogleSignInAccount account = completedTask.getResult(ApiException.class);
            // Store the account from the result
            mAccount = account.getAccount();
            // Asynchronously access the People API for the account
            getContacts();
        } catch (ApiException e) {
            // Clear the local account
            mAccount = null;
            dismissDialog();
            Toast.makeText(this, "Get contacts failed.", Toast.LENGTH_SHORT).show();
        }
    }

    private void getContacts() {
        if (mAccount == null) {
            Logger.e("getContacts: null account");
            dismissDialog();
            SLToast.error("Get contacts failed.");
            return;
        }
        new AddressBookActivity.GetContactsTask(AddressBookActivity.this).execute(mAccount);
    }

    private static class GetContactsTask extends AsyncTask<Account, Void, List<Person>> {

        private WeakReference<AddressBookActivity> mActivityRef;

        public GetContactsTask(AddressBookActivity activity) {
            mActivityRef = new WeakReference<>(activity);
        }

        @Override
        protected List<Person> doInBackground(Account... accounts) {
            if (mActivityRef.get() == null) {
                SLToast.error("Get contacts failed.");
                return null;
            }

            Context context = mActivityRef.get().getApplicationContext();

            try {
                GoogleAccountCredential credential = GoogleAccountCredential.usingOAuth2(
                        context,
                        Collections.singleton(CONTACTS_SCOPE));

                credential.setSelectedAccount(accounts[0]);

                PeopleService service = new PeopleService.Builder(HTTP_TRANSPORT, new GsonFactory(), credential)
                        .setApplicationName("TuneKey")
                        .setHttpRequestInitializer(credential)
                        .build();
                ListConnectionsResponse connectionsResponse = service
                        .people()
                        .connections()
                        .list("people/me")
                        .setPageSize(2000)
                        .setPersonFields("names,emailAddresses")
                        .execute();


//                Logger.json(SLJsonUtils.toJsonString(connectionsResponse.getConnections()));
                return connectionsResponse.getConnections();

            } catch (UserRecoverableAuthIOException recoverableException) {
                if (mActivityRef.get() != null) {
                    mActivityRef.get().onRecoverableAuthException(recoverableException);
                }
            } catch (IOException e) {
                Logger.e("getContacts:exception" + e);
            }

            return null;
        }

        @Override
        protected void onPostExecute(List<Person> people) {
            super.onPostExecute(people);
            if (mActivityRef.get() != null) {
                mActivityRef.get().onConnectionsLoadFinished(people);
            }
        }
    }

    protected void onRecoverableAuthException(UserRecoverableAuthIOException recoverableException) {
        Logger.e("onRecoverableAuthException", recoverableException);
        startActivityForResult(recoverableException.getIntent(), RC_RECOVERABLE);
    }

    protected void onConnectionsLoadFinished(@Nullable List<Person> connections) {
        dismissDialog();

        if (connections == null) {
            Logger.e("getContacts:connections: null");
            SLToast.error("Get contacts failed.");
            return;
        }
        //不为空 跳到下一个页面 传list<Person>
        //startActivity(AddressBookActivity.class);
        List<GooglePeopleEntity> googlePeopleEntities = SLJsonUtils.toList(SLJsonUtils.toJsonString(connections), GooglePeopleEntity.class);
        //您google contact 中没添加联系人
//        SLToast.warning("You have no contacts in your Google account.");

//        Logger.e("getContacts:connections: size=" + connections.size());
        List<AddressBookEntity> addressBookEntities = new ArrayList<>();
        for (int i = 0; i < googlePeopleEntities.size(); i++) {
            GooglePeopleEntity googlePeopleEntity = googlePeopleEntities.get(i);
            if (googlePeopleEntity.getEmailAddresses() != null && googlePeopleEntity.getEmailAddresses().size() > 0) {
                AddressBookEntity entity = new AddressBookEntity();
                entity.setId(i);
                entity.setEmail(googlePeopleEntity.getEmailAddresses().get(0).getValue());
                entity.setName(googlePeopleEntity.getEmailAddresses().get(0).getValue());
                if (googlePeopleEntity.getNames() != null && googlePeopleEntity.getNames().size() > 0 && googlePeopleEntity.getNames().get(0).getDisplayName() != null) {
                    entity.setName(googlePeopleEntity.getNames().get(0).getDisplayName());
                }
                addressBookEntities.add(entity);
            }
        }
        viewModel.getGoogleContact(addressBookEntities);

    }


}
