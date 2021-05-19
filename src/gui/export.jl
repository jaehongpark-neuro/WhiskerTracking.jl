
function add_export_callbacks(b::Gtk.GtkBuilder,handles::Tracker_Handles)

    signal_connect(export_button_cb,b["export_button"],"clicked",Void,(),false,(handles,))

    nothing
end

function export_button_cb(w::Ptr,user_data::Tuple{Tracker_Handles})

    han, = user_data

    setproperty!(han.b["export_button"],:label,"Exporting to MAT file...")

    e_angle = getproperty(han.b["angle_export_button"],:active,Bool)
    e_curve = getproperty(han.b["curvature_export_button"],:active,Bool)
    e_phase = getproperty(han.b["phase_export"],:active,Bool)

    # separate left and right whisker based on the relative position of whiskers to the pad pos
    pos_ind = findfirst(x -> x < han.wt.pad_pos[1], han.nn.predicted[:,1,1]) # first right whisker position

    #Convert to Janelia
    (my_whiskers,mytracked)=convert_discrete_to_janelia(han.nn.predicted[1:pos_ind-1,:,:],han.nn.confidence_thres,han.wt.pad_pos); #parsing left
    (my_whiskers_r,mytracked_r)=convert_discrete_to_janelia(han.nn.predicted[pos_ind:end,:,:],han.nn.confidence_thres,han.wt.pad_pos); #parsing right
    face_axis_num=getproperty(han.b["face_axis_combo"],:active,Int64)

    # for left
    if face_axis_num == 0
        (mycurv,myangles)=get_curv_and_angle(my_whiskers,mytracked,han.wt.pad_pos);
    else
        (mycurv,myangles)=get_curv_and_angle(my_whiskers,mytracked,han.wt.pad_pos,face_axis='y');
    end

    # for right
    if face_axis_num == 0
        (mycurv_r,myangles_r)=get_curv_and_angle(my_whiskers_r,mytracked_r,han.wt.pad_pos);
    else
        (mycurv_r,myangles_r)=get_curv_and_angle(my_whiskers_r,mytracked_r,han.wt.pad_pos,face_axis='y');
    end


    #Whisking phase calculation
    phase_low_band=8.0 #Band pass filter lower band
    phase_high_band=30.0 #Band pass filter upper band
    myphase=WhiskerTracking_HG.get_phase(myangles,bp_l=phase_low_band,bp_h=phase_high_band);

    filepath=string(han.wt.data_path,"output.mat")
    file=matopen(filepath,"w")
        if e_angle
            write(file,"Angles",myangles)
            write(file,"Angles_r",myangles_r)
        end
        if e_curve
            write(file,"Curvature",mycurv)
        end
        if e_phase
            write(file,"Phase",myphase)
        end
    write(file,"Tracked",mytracked)
    write(file,"Tracked_r",mytracked_r)
    close(file)

    setproperty!(han.b["export_button"],:label,"Export")
    println("Export complete")

    nothing
end
